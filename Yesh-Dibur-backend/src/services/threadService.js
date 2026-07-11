const { pool } = require('../config/db');
const { getChannel } = require('../config/rabbitmq');

const threadService = {
  
  getThread: async (id, requesterId) => {
    const query = `
      SELECT t.*, u.name as author_name, u.profile_image_url as author_image,
             EXISTS(SELECT 1 FROM thread_likes tl WHERE tl.thread_id = t.id AND tl.user_id = $2) as is_liked
      FROM threads t
      JOIN users u ON t.author_id = u.id
      WHERE t.id = $1 
        AND t.deleted_at IS NULL
        AND u.deleted_at IS NULL
        AND (t.moderation_status = 'approved' OR t.author_id = $2) -- אטימת פרצה: הצגת פוסט רק אם אושר (או אם המבקש הוא היוצר)
        AND t.author_id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        );
    `;
    const { rows } = await pool.query(query, [id, requesterId]);
    return rows[0];
  },

  getGroupThreads: async (groupId, requesterId, limit, offset) => {
    // שליפת הפוסטים של הקבוצה עם סינון מחברים שנמחקו/נחסמו, ובדיקת סטטוס 'לייק'
    const query = `
      SELECT t.*, u.name as author_name, u.profile_image_url as author_image,
             EXISTS(SELECT 1 FROM thread_likes tl WHERE tl.thread_id = t.id AND tl.user_id = $2) as is_liked
      FROM threads t
      JOIN users u ON t.author_id = u.id
      WHERE t.group_id = $1 
        AND t.deleted_at IS NULL
        AND u.deleted_at IS NULL
        AND (t.moderation_status = 'approved' OR t.author_id = $2) -- אטימת הבאג: הצגת פוסטים ממתינים למחבר עצמו
        AND t.author_id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        )
      ORDER BY t.created_at DESC
      LIMIT $3 OFFSET $4;
      `;
    const { rows } = await pool.query(query, [groupId, requesterId, limit, offset]); // העברת המשתנים החדשים
    return rows;
  },

  createThread: async (authorId, data) => {

    // 1. שמירת הפוסט במסד הנתונים - אנו משתמשים ב-SELECT כדי לוודא שהיוצר הוא אכן חבר בקבוצה!
const query = `
      INSERT INTO threads (group_id, author_id, content, bg_type, bg_value, aspect_ratio, moderation_status)
      SELECT group_id, user_id, $3, $4, $5, $6, 'pending'
      FROM group_members
      WHERE group_id = $1 AND user_id = $2
      RETURNING *;
    `;
    const values = [data.group_id, authorId, data.content, data.bg_type, data.bg_value, data.aspect_ratio || null];
    const { rows } = await pool.query(query, values);
    
    // אם לא הוכנסה שורה, המשתמש לא חבר בקבוצה או שהיא לא קיימת
    if (rows.length === 0) throw new Error('GROUP_NOT_FOUND');
    const newThread = rows[0];

    // מניעת קריסה באפליקציה: הוספת פרטי המחבר לפוסט החדש כדי שיוצג מיד על המסך
    const userRes = await pool.query('SELECT name, profile_image_url FROM users WHERE id = $1', [authorId]);
    newThread.author_name = userRes.rows[0].name;
    newThread.author_image = userRes.rows[0].profile_image_url;
    newThread.is_liked = false; // ברירת מחדל לפוסט שזה עתה נוצר

    // 2. זריקת משימה לתור הסינון של Gemini (AI Moderation Queue)
    const channel = getChannel();
    if (channel) {
      const moderationPayload = {
        type: 'thread',
        threadId: newThread.id,
        content: newThread.content
      };
      channel.publish('', 'moderation', Buffer.from(JSON.stringify(moderationPayload)));
    }

    return newThread;
  },

  deleteThread: async (threadId, userId) => {
    // מחיקה רכה. הלוגיקה מוודאת שהמוחק הוא או כותב הפוסט, או מנהל הקבוצה שאליה הפוסט שייך.
    const query = `
      UPDATE threads
      SET deleted_at = CURRENT_TIMESTAMP
      WHERE id = $1 
      AND (
        author_id = $2 
        OR (SELECT admin_id FROM groups WHERE id = threads.group_id) = $2
      )
      RETURNING id;
    `;
    const { rows } = await pool.query(query, [threadId, userId]);
    return rows.length > 0;
  },

  toggleLike: async (threadId, userId) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // בדיקת קיום הפוסט, שהוא לא נמחק, ושהמשתמש חבר בקבוצה שלו (Gatekeeper)
      const checkThread = await client.query(`
        SELECT 1 FROM threads t 
        JOIN group_members gm ON t.group_id = gm.group_id 
        WHERE t.id = $1 AND gm.user_id = $2 AND t.deleted_at IS NULL
      `, [threadId, userId]);
      
      if (checkThread.rows.length === 0) {
        await client.query('ROLLBACK');
        throw new Error('NOT_AUTHORIZED');
      }

      // בדיקה אם המשתמש כבר עשה לייק בעבר
      const checkQuery = 'SELECT * FROM thread_likes WHERE thread_id = $1 AND user_id = $2';
      const checkRes = await client.query(checkQuery, [threadId, userId]);

      let liked = false;

      if (checkRes.rows.length > 0) {
        // המשתמש עשה לייק בעבר, לכן מסירים אותו ומורידים את המונה
        await client.query('DELETE FROM thread_likes WHERE thread_id = $1 AND user_id = $2', [threadId, userId]);
        await client.query('UPDATE threads SET likes_count = likes_count - 1 WHERE id = $1', [threadId]);
      } else {
        // הוספת הלייק והעלאת המונה
        await client.query('INSERT INTO thread_likes (thread_id, user_id) VALUES ($1, $2)', [threadId, userId]);
        const threadRes = await client.query('UPDATE threads SET likes_count = likes_count + 1 WHERE id = $1 RETURNING author_id, group_id', [threadId]);
        liked = true;

        const authorId = threadRes.rows[0].author_id;
        const groupId = threadRes.rows[0].group_id; // חולץ בהצלחה
        const channel = getChannel();
        if (channel && authorId !== userId) {
          const pushPayload = { type: 'like', threadId, groupId, senderId: userId, receiverId: authorId }; // הוספנו את ה-groupId!
          channel.publish('', 'push', Buffer.from(JSON.stringify(pushPayload)));
        }
      }

      await client.query('COMMIT');
      return { liked };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  getComments: async (threadId, requesterId, limit, offset) => {
    const query = `
      SELECT c.*, u.name as author_name, u.profile_image_url as author_image
      FROM thread_comments c
      JOIN users u ON c.author_id = u.id
      JOIN threads t ON c.thread_id = t.id
      JOIN group_members gm ON t.group_id = gm.group_id
      WHERE c.thread_id = $1 
        AND gm.user_id = $2 -- שומר סף: רק חברי קבוצה יכולים לקרוא תגובות!
        AND t.deleted_at IS NULL -- חסימת קריאת תגובות של פוסט מחוק
        AND (c.moderation_status = 'approved' OR c.author_id = $2) -- אטימת פרצה: הצגת תגובה רק אם אושרה (או למחבר עצמו)
        AND u.deleted_at IS NULL
        AND c.author_id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        )
      ORDER BY c.created_at ASC
      LIMIT $3 OFFSET $4;
    `;
    const { rows } = await pool.query(query, [threadId, requesterId, limit, offset]);
    return rows;
  },

  createComment: async (threadId, authorId, data) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // בדיקת חברות בקבוצה שבה נמצא הפוסט (חסימת הזרקת תגובות מבחוץ)
      const checkGroup = await client.query(`
        SELECT 1 FROM threads t 
        JOIN group_members gm ON t.group_id = gm.group_id 
        WHERE t.id = $1 AND gm.user_id = $2 AND t.deleted_at IS NULL
      `, [threadId, authorId]);
      
      if (checkGroup.rows.length === 0) {
        await client.query('ROLLBACK');
        throw new Error('NOT_AUTHORIZED');
      }

      // 1. הוספת התגובה לטבלה
      const insertQuery = `
        INSERT INTO thread_comments (thread_id, author_id, content, image_url, aspect_ratio, moderation_status)
        VALUES ($1, $2, $3, $4, $5, 'pending')
        RETURNING *;
      `;
      const values = [threadId, authorId, data.content, data.image_url || null, data.aspect_ratio || null];
      const res = await client.query(insertQuery, values);
      const newComment = res.rows[0];

      // מניעת קריסה באפליקציה: הוספת פרטי המחבר לתגובה החדשה
      const userRes = await client.query('SELECT name, profile_image_url FROM users WHERE id = $1', [authorId]);
      newComment.author_name = userRes.rows[0].name;
      newComment.author_image = userRes.rows[0].profile_image_url;

      // 2. עדכון המונה בטבלת הפוסטים הראשיים ושליפת מזהה הקבוצה עבור ההתראה (Deep Link)
      const updateThread = await client.query('UPDATE threads SET comments_count = comments_count + 1 WHERE id = $1 RETURNING author_id, group_id', [threadId]);

      // 3. תהליכי רקע: סינון התגובה + התראה למחבר הפוסט
      const channel = getChannel();
      if (channel) {
        // תור סינון (AI)
        const modPayload = { type: 'comment', threadId: newComment.id, content: newComment.content };
        channel.publish('', 'moderation', Buffer.from(JSON.stringify(modPayload)));

        // תור התראות למחבר הפוסט (Push) - עכשיו האפליקציה תדע לאיזו קבוצה לנווט!
        const postAuthorId = updateThread.rows[0].author_id;
        const groupId = updateThread.rows[0].group_id; 
        if (postAuthorId !== authorId) {
          const pushPayload = { type: 'comment', threadId, groupId, senderId: authorId, receiverId: postAuthorId, content: newComment.content };
          channel.publish('', 'push', Buffer.from(JSON.stringify(pushPayload)));
        }
      }

      await client.query('COMMIT');
      return newComment;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  deleteComment: async (threadId, commentId, userId) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // בדיקת הרשאות (מחבר התגובה, או מחבר הפוסט, או מנהל הקבוצה)
      const checkQuery = `
        SELECT c.id FROM thread_comments c
        JOIN threads t ON c.thread_id = t.id
        WHERE c.id = $1 AND c.thread_id = $2
        AND (
          c.author_id = $3 
          OR t.author_id = $3 
          OR (SELECT admin_id FROM groups WHERE id = t.group_id) = $3
        );
      `;
      const checkRes = await client.query(checkQuery, [commentId, threadId, userId]);
      
      if (checkRes.rows.length === 0) {
        await client.query('ROLLBACK');
        return false;
      }

      // מחיקה בפועל של התגובה והורדת מונה התגובות מהפוסט
      const deleteRes = await client.query('DELETE FROM thread_comments WHERE id = $1 RETURNING id', [commentId]);
      
      if (deleteRes.rowCount > 0) {
        await client.query('UPDATE threads SET comments_count = comments_count - 1 WHERE id = $1', [threadId]);
      }

      await client.query('COMMIT');
      return true;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
};

module.exports = threadService;