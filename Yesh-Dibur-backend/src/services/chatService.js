const { pool } = require('../config/db');

const chatService = {
  createConversation: async (userId1, userId2) => {
    if (userId1 === userId2) throw new Error('CANNOT_CHAT_WITH_SELF');

    // סידור המזהים בצורה אלפביתית כדי למנוע כפילויות (תמיד user1 יהיה הקטן מביניהם)
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

  getUserChats: async (uid) => {
    // שליפת תיבות השיחה יחד עם פרטי המשתמש השני ותקציר ההודעה האחרונה
    const query = `
      SELECT c.id, c.updated_at,
             u.id as other_user_id, u.name as other_user_name, u.profile_image_url,
             m.content as last_message_content, m.created_at as last_message_time, m.status
      FROM conversations c
      JOIN users u ON (u.id = CASE WHEN c.user1_id = $1 THEN c.user2_id ELSE c.user1_id END)
      LEFT JOIN messages m ON c.last_message_id = m.id
      WHERE c.user1_id = $1 OR c.user2_id = $1
      ORDER BY c.updated_at DESC;
    `;
    const { rows } = await pool.query(query, [uid]);
    return rows;
  },

  getChatMessages: async (conversationId, uid) => {
    // אימות אבטחה (לוודא שהמשתמש שייך לשיחה הזו)
    const checkQuery = `SELECT * FROM conversations WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`;
    const checkRes = await pool.query(checkQuery, [conversationId, uid]);
    if (checkRes.rows.length === 0) throw new Error('UNAUTHORIZED_ACCESS');

    const query = `
      SELECT id, sender_id, receiver_id, content, image_url, aspect_ratio, status, created_at
      FROM messages
      WHERE conversation_id = $1
      ORDER BY created_at ASC;
    `;
    const { rows } = await pool.query(query, [conversationId]);
    return rows;
  },

  saveMessage: async (senderId, receiverId, conversationId, content, imageUrl, aspectRatio) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // שמירת ההודעה בטבלת messages
      const insertMsgQuery = `
        INSERT INTO messages (conversation_id, sender_id, receiver_id, content, image_url, aspect_ratio)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *;
      `;
      const msgRes = await client.query(insertMsgQuery, [conversationId, senderId, receiverId, content, imageUrl, aspectRatio]);
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