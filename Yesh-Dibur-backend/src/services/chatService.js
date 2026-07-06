const { pool } = require('../config/db');

const chatService = {
  createConversation: async (userId1, userId2) => {
    if (userId1 === userId2) throw new Error('CANNOT_CHAT_WITH_SELF');

    // שומר סף הרמטי: בדיקת חסימות (הדדית), משתמשים מחוקים, והפרדת גילאים
    const checkQuery = `
      SELECT u1.id FROM users u1, users u2
      WHERE u1.id = $1 AND u2.id = $2
        AND u2.deleted_at IS NULL
        AND u2.id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $1 
          UNION 
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $1
        )
        AND (
          (EXTRACT(YEAR FROM age(u1.birth_date)) < 18 AND EXTRACT(YEAR FROM age(u2.birth_date)) < 18)
          OR
          (EXTRACT(YEAR FROM age(u1.birth_date)) >= 18 AND EXTRACT(YEAR FROM age(u2.birth_date)) >= 18)
        )
    `;
    const checkRes = await pool.query(checkQuery, [userId1, userId2]);
    if (checkRes.rows.length === 0) throw new Error('NOT_ALLOWED');

    const [u1, u2] = [userId1, userId2].sort();
    const query = `
      INSERT INTO conversations (user1_id, user2_id)
      VALUES ($1, $2)
      ON CONFLICT (user1_id, user2_id) 
      DO UPDATE SET updated_at = CURRENT_TIMESTAMP
      RETURNING *;
    `;
    const { rows } = await pool.query(query, [u1, u2]);
    return rows[0];
  },

  getUserChats: async (uid, limit = 20, offset = 0) => {
    // הוספת עימוד למניעת קריסת שרת, ושליפת תמונת ההודעה האחרונה לטובת חיווי ב-UI
    const query = `
      SELECT c.id, c.updated_at,
             u.id as other_user_id, u.name as other_user_name, u.profile_image_url,
             m.content as last_message_content, m.image_url as last_message_image, m.created_at as last_message_time, m.status,
             (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND receiver_id = $1 AND status IN ('approved', 'pending_approval')) as unread_count
      FROM conversations c
      JOIN users u ON (u.id = CASE WHEN c.user1_id = $1 THEN c.user2_id ELSE c.user1_id END)
      LEFT JOIN messages m ON c.last_message_id = m.id
      WHERE (c.user1_id = $1 OR c.user2_id = $1)
        AND u.deleted_at IS NULL
        AND u.id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $1
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $1
        )
      ORDER BY c.updated_at DESC
      LIMIT $2 OFFSET $3;
    `;
    const { rows } = await pool.query(query, [uid, limit, offset]);
    return rows;
  },

  getChatMessages: async (conversationId, uid, limit, offset) => {
    // שומר סף: חסימת קריאת היסטוריית הודעות מול משתמשים שחסמו אותי או שמחקו את חשבונם
    const checkQuery = `
      SELECT c.id FROM conversations c
      JOIN users u ON u.id = CASE WHEN c.user1_id = $2 THEN c.user2_id ELSE c.user1_id END
      WHERE c.id = $1 
        AND (c.user1_id = $2 OR c.user2_id = $2)
        AND u.deleted_at IS NULL
        AND u.id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        )
    `;
    const checkRes = await pool.query(checkQuery, [conversationId, uid]);
    if (checkRes.rows.length === 0) throw new Error('UNAUTHORIZED_ACCESS');

    // שליפה הפוכה (DESC) עם Limit לטובת גלילה חלקה באפליקציה ממטה למעלה
    const query = `
      SELECT id, sender_id, receiver_id, content, image_url, aspect_ratio, status, created_at
      FROM messages
      WHERE conversation_id = $1
      ORDER BY created_at DESC
      LIMIT $2 OFFSET $3;
    `;
    const { rows } = await pool.query(query, [conversationId, limit, offset]);
    return rows;
  },

  verifyParticipant: async (conversationId, userId) => {
    // שומר סף לחדר הסוקט: חסימת האזנה לשיחות של משתמשים חסומים או מחוקים
    const query = `
      SELECT c.id FROM conversations c
      JOIN users u ON u.id = CASE WHEN c.user1_id = $2 THEN c.user2_id ELSE c.user1_id END
      WHERE c.id = $1 
        AND (c.user1_id = $2 OR c.user2_id = $2)
        AND u.deleted_at IS NULL
        AND u.id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        )
    `;
    const { rows } = await pool.query(query, [conversationId, userId]);
    return rows.length > 0;
  },

  saveMessage: async (senderId, receiverId, conversationId, content, imageUrl, aspectRatio) => {
    // שומר סף משולב: מוודא שהשולח שייך לשיחה הזו (!), וגם שהמקבל קיים ולא חסם אותו
    const checkQuery = `
      SELECT c.id FROM conversations c
      JOIN users u ON u.id = $1
      WHERE c.id = $2 
        AND (c.user1_id = $3 OR c.user2_id = $3)
        AND (c.user1_id = $1 OR c.user2_id = $1) -- אטימת פרצת ההזרקה: חובה לוודא שהמקבל הוא באמת חלק מהשיחה!
        AND u.deleted_at IS NULL
        AND u.id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $3 
          UNION 
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $3
        )
    `;
    const checkRes = await pool.query(checkQuery, [receiverId, conversationId, senderId]);
    if (checkRes.rows.length === 0) throw new Error('BLOCKED_OR_UNAUTHORIZED');

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. מניעת לולאת אישורים: קביעת סטטוס דינמי להודעה
      // אם המקבל אישר בעבר או שלח הודעה בעצמו באותה שיחה, הסטטוס מאושר אוטומטית.
      const statusCheck = await client.query(`
        SELECT 1 FROM messages 
        WHERE conversation_id = $1 
          AND (sender_id = $2 OR status IN ('approved', 'read'))
        LIMIT 1
      `, [conversationId, receiverId]);
      
      const msgStatus = statusCheck.rows.length > 0 ? 'approved' : 'pending_approval';

      // 2. שמירת ההודעה במסד הנתונים (כולל תמיכה בהודעות ללא טקסט עם content || '')
      const insertMsgQuery = `
        INSERT INTO messages (conversation_id, sender_id, receiver_id, content, image_url, aspect_ratio, status)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *;
      `;
      const msgRes = await client.query(insertMsgQuery, [conversationId, senderId, receiverId, content || '', imageUrl, aspectRatio, msgStatus]);
      const newMessage = msgRes.rows[0];

      // עדכון המצביע להודעה האחרונה בתיבת השיחה
      const updateConvQuery = `
        UPDATE conversations
        SET last_message_id = $1, updated_at = CURRENT_TIMESTAMP
        WHERE id = $2;
      `;
      await client.query(updateConvQuery, [newMessage.id, conversationId]);

      await client.query('COMMIT');
      return newMessage;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  approveChat: async (conversationId, receiverId) => {
    // מעדכן את כל ההודעות שממתינות לאישור בשיחה הזו והמשתמש הנוכחי הוא המקבל שלהן
    const query = `
      UPDATE messages
      SET status = 'approved'
      WHERE conversation_id = $1 AND receiver_id = $2 AND status = 'pending_approval';
    `;
    await pool.query(query, [conversationId, receiverId]);
  },

  markMessagesAsRead: async (conversationId, receiverId) => {
    // מעדכן ל'נקרא' רק את ההודעות שאושרו ונשלחו אלי
    const query = `
      UPDATE messages
      SET status = 'read'
      WHERE conversation_id = $1 AND receiver_id = $2 AND status = 'approved';
    `;
    await pool.query(query, [conversationId, receiverId]);
  }
};

module.exports = chatService;