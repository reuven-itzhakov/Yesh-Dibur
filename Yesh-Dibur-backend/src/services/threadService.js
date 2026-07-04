const { pool } = require('../config/db');
const { getChannel } = require('../config/rabbitmq');

const threadService = {
  
  getThread: async (id) => {
    const query = `
      SELECT t.*, u.name as author_name, u.profile_image_url as author_image
      FROM threads t
      JOIN users u ON t.author_id = u.id
      WHERE t.id = $1 AND t.deleted_at IS NULL;
    `;
    const { rows } = await pool.query(query, [id]);
    return rows[0];
  },

  getGroupThreads: async (groupId) => {
    // שליפת הפוסטים של הקבוצה יחד עם פרטי המחבר, מסודרים מהחדש לישן
    const query = `
      SELECT t.*, u.name as author_name, u.profile_image_url as author_image
      FROM threads t
      JOIN users u ON t.author_id = u.id
      WHERE t.group_id = $1 AND t.deleted_at IS NULL
      ORDER BY t.created_at DESC;
    `;
    const { rows } = await pool.query(query, [groupId]);
    return rows;
  },

  createThread: async (authorId, data) => {
    // 1. שמירת הפוסט במסד הנתונים
    const query = `
      INSERT INTO threads (group_id, author_id, content, bg_type, bg_value, aspect_ratio, moderation_status)
      VALUES ($1, $2, $3, $4, $5, $6, 'pending')
      RETURNING *;
    `;
    const values = [data.group_id, authorId, data.content, data.bg_type, data.bg_value, data.aspect_ratio || null];
    const { rows } = await pool.query(query, values);
    const newThread = rows[0];

    // 2. זריקת משימה לתור הסינון של Gemini (AI Moderation Queue)
    const channel = getChannel();
    if (channel) {
      const moderationPayload = {
        type: 'thread',
        target_id: newThread.id,
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
        const threadRes = await client.query('UPDATE threads SET likes_count = likes_count + 1 WHERE id = $1 RETURNING author_id', [threadId]);
        liked = true;

        // שליחת התראת לייק למחבר הפוסט (Push Notification)
        const authorId = threadRes.rows[0].author_id;
        const channel = getChannel();
        if (channel && authorId !== userId) {
          const pushPayload = { type: 'like', threadId, senderId: userId, receiverId: authorId };
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

  getComments: async (threadId) => {
    const query = `
      SELECT c.*, u.name as author_name, u.profile_image_url as author_image
      FROM thread_comments c
      JOIN users u ON c.author_id = u.id
      WHERE c.thread_id = $1 AND c.moderation_status != 'rejected'
      ORDER BY c.created_at ASC;
    `;
    const { rows } = await pool.query(query, [threadId]);
    return rows;
  },

  createComment: async (threadId, authorId, data) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. הוספת התגובה לטבלה
      const insertQuery = `
        INSERT INTO thread_comments (thread_id, author_id, content, image_url, aspect_ratio, moderation_status)
        VALUES ($1, $2, $3, $4, $5, 'pending')
        RETURNING *;
      `;
      const values = [threadId, authorId, data.content, data.image_url || null, data.aspect_ratio || null];
      const res = await client.query(insertQuery, values);
      const newComment = res.rows[0];

      // 2. עדכון המונה בטבלת הפוסטים הראשיים
      const updateThread = await client.query('UPDATE threads SET comments_count = comments_count + 1 WHERE id = $1 RETURNING author_id', [threadId]);

      // 3. תהליכי רקע: סינון התגובה + התראה למחבר הפוסט
      const channel = getChannel();
      if (channel) {
        // תור סינון (AI)
        const modPayload = { type: 'comment', target_id: newComment.id, content: newComment.content };
        channel.publish('', 'moderation', Buffer.from(JSON.stringify(modPayload)));

        // תור התראות למחבר הפוסט (Push)
        const postAuthorId = updateThread.rows[0].author_id;
        if (postAuthorId !== authorId) {
          const pushPayload = { type: 'comment', threadId, senderId: authorId, receiverId: postAuthorId, content: newComment.content };
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
      await client.query('DELETE FROM thread_comments WHERE id = $1', [commentId]);
      await client.query('UPDATE threads SET comments_count = comments_count - 1 WHERE id = $1', [threadId]);

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