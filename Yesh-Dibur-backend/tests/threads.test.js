const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { getChannel } = require('../src/config/rabbitmq');

// 1. חיקוי (Mock) למערכת ההזדהות
const authMiddleware = require('../src/middlewares/auth');
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    req.user = { uid: 'author_uid' }; 
    next();
  });
});

// 2. חיקוי (Mock) ל-RabbitMQ כדי שהטסטים לא יקרסו בניסיון חיבור לתור
// 2. חיקוי (Mock) ל-RabbitMQ כדי שהטסטים לא יקרסו בניסיון חיבור לתור
const mockChannel = {
  publish: jest.fn()
};

jest.mock('../src/config/rabbitmq', () => ({
  getChannel: jest.fn(() => mockChannel)
}));

describe('Threads API Integration Tests', () => {
  const authorId = 'author_uid';
  const adminId = 'admin_uid';
  const otherUserId = 'other_user_uid';
  let testGroupId;

  beforeAll(async () => {
    // מחיקת נתונים קודמים מהסוף להתחלה כדי לשמור על Foreign Keys
    await pool.query('DELETE FROM thread_comments');
    await pool.query('DELETE FROM thread_likes');
    await pool.query('DELETE FROM threads');
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [authorId, adminId, otherUserId]);

    // יצירת משתמשים
    const insertUserQuery = `INSERT INTO users (id, name, email, birth_date) VALUES ($1, $2, $3, $4)`;
    await pool.query(insertUserQuery, [authorId, 'Author', 'author@test.com', new Date()]);
    await pool.query(insertUserQuery, [adminId, 'Admin', 'admin@test.com', new Date()]);
    await pool.query(insertUserQuery, [otherUserId, 'Other', 'other@test.com', new Date()]);

    // יצירת קבוצה לצורך הפוסטים (Zod דורש ש-group_id יהיה UUID תקין)
    const groupRes = await pool.query(
      'INSERT INTO groups (name, admin_id) VALUES ($1, $2) RETURNING id',
      ['Test Group', adminId]
    );
    testGroupId = groupRes.rows[0].id;
  });

  beforeEach(async () => {
    // ניקוי טבלאות הפוסטים לפני כל טסט
    await pool.query('DELETE FROM thread_comments');
    await pool.query('DELETE FROM thread_likes');
    await pool.query('DELETE FROM threads');
    
    // איפוס המוק של משתמש מחובר חזרה לכותב הפוסטים
    authMiddleware.mockImplementation((req, res, next) => {
      req.user = { uid: authorId };
      next();
    });

    // איפוס ספירת הקריאות של ה-Mock של RabbitMQ
    jest.clearAllMocks();
  });

  afterAll(async () => {
    await pool.query('DELETE FROM thread_comments');
    await pool.query('DELETE FROM thread_likes');
    await pool.query('DELETE FROM threads');
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [authorId, adminId, otherUserId]);
    await pool.end();
  });

  // ==========================================
  // יצירת ושליפת פוסטים (Threads)
  // ==========================================
  describe('POST & GET /api/v1/threads', () => {
    it('should create a new thread and send to moderation queue', async () => {
      const threadData = {
        group_id: testGroupId,
        content: 'שלום לכולם, זה הפוסט הראשון שלי',
        bg_type: 'color',
        bg_value: '#FF5733'
      };

      const response = await request(app).post('/api/v1/threads').send(threadData);

      expect(response.statusCode).toBe(201);
      expect(response.body.content).toBe(threadData.content);
      expect(response.body.moderation_status).toBe('pending');

      // וידוא ש-RabbitMQ נקרא כדי לסנן את התוכן דרך Gemini
      const mockChannel = getChannel();
      expect(mockChannel.publish).toHaveBeenCalledWith(
        '', 
        'moderation', 
        expect.any(Buffer) // וידוא שנשלח באפר
      );
    });

    it('should fail validation if bg_type is invalid', async () => {
      const response = await request(app).post('/api/v1/threads').send({
        group_id: testGroupId,
        content: 'תוכן תקין',
        bg_type: 'video', // שגוי, ה-Zod מאפשר רק image או color
        bg_value: 'url'
      });
      expect(response.statusCode).toBe(400);
    });

    it('should get a specific thread by ID', async () => {
      // יצירת פוסט ב-DB
      const insertRes = await pool.query(`
        INSERT INTO threads (group_id, author_id, content, bg_type, bg_value)
        VALUES ($1, $2, $3, $4, $5) RETURNING id
      `, [testGroupId, authorId, 'טסט שליפה', 'color', '#000']);
      const threadId = insertRes.rows[0].id;

      const response = await request(app).get(`/api/v1/threads/${threadId}`);
      expect(response.statusCode).toBe(200);
      expect(response.body.content).toBe('טסט שליפה');
      expect(response.body.author_name).toBe('Author'); // שמצטרף מה-JOIN לטבלת משתמשים
    });
  });

  // ==========================================
  // GET /api/v1/groups/:id/threads - שליפת הפוסטים של הקבוצה
  // ==========================================
  describe('GET /api/v1/groups/:id/threads', () => {
    it('should fetch all threads for a specific group ordered by newest first', async () => {
      // ניצור שני פוסטים שונים לאותה קבוצה
      await pool.query(`
        INSERT INTO threads (group_id, author_id, content, bg_type, bg_value)
        VALUES ($1, $2, $3, $4, $5)
      `, [testGroupId, authorId, 'פוסט ראשון וישן יותר', 'color', '#111']);

      // השהייה קטנטנה כדי שחותמת הזמן תהיה שונה בוודאות
      await new Promise(resolve => setTimeout(resolve, 50));

      await pool.query(`
        INSERT INTO threads (group_id, author_id, content, bg_type, bg_value)
        VALUES ($1, $2, $3, $4, $5)
      `, [testGroupId, authorId, 'פוסט שני וחדש יותר', 'color', '#222']);

      const response = await request(app).get(`/api/v1/groups/${testGroupId}/threads`);

      expect(response.statusCode).toBe(200);
      expect(response.body.length).toBe(2);
      
      // וידוא שהפוסט החדש ביותר מופיע ראשון ברשימה (ORDER BY created_at DESC)
      expect(response.body[0].content).toBe('פוסט שני וחדש יותר');
      expect(response.body[1].content).toBe('פוסט ראשון וישן יותר');
    });

    it('should return an empty array if the group has no threads', async () => {
      // נמציא מזהה קבוצה פיקטיבי אבל חוקי מבחינת UUID
      const emptyGroupId = '123e4567-e89b-12d3-a456-426614174000';
      const response = await request(app).get(`/api/v1/groups/${emptyGroupId}/threads`);
      
      expect(response.statusCode).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBe(0);
    });
  });

  // ==========================================
  // פעולות מחיקה וניהול הרשאות
  // ==========================================
  describe('DELETE /api/v1/threads/:id', () => {
    let threadId;

    beforeEach(async () => {
      const insertRes = await pool.query(`
        INSERT INTO threads (group_id, author_id, content, bg_type, bg_value)
        VALUES ($1, $2, $3, $4, $5) RETURNING id
      `, [testGroupId, authorId, 'פוסט למחיקה', 'color', '#000']);
      threadId = insertRes.rows[0].id;
    });

    it('should allow the author to delete their own thread', async () => {
      const response = await request(app).delete(`/api/v1/threads/${threadId}`);
      expect(response.statusCode).toBe(204);

      // וידוא מחיקה רכה (Soft Delete)
      const dbCheck = await pool.query('SELECT deleted_at FROM threads WHERE id = $1', [threadId]);
      expect(dbCheck.rows[0].deleted_at).not.toBeNull();
    });

    it('should allow the group admin to delete someone else\'s thread', async () => {
      // נשנה את המשתמש למנהל הקבוצה
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: adminId };
        next();
      });

      const response = await request(app).delete(`/api/v1/threads/${threadId}`);
      expect(response.statusCode).toBe(204);
    });

    it('should block an unauthorized user from deleting the thread', async () => {
      // נשנה את המשתמש לאדם זר
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: otherUserId };
        next();
      });

      const response = await request(app).delete(`/api/v1/threads/${threadId}`);
      expect(response.statusCode).toBe(403);
    });
  });

  // ==========================================
  // לייקים (Toggle Like)
  // ==========================================
  describe('POST /api/v1/threads/:id/like', () => {
    let threadId;

    beforeEach(async () => {
      const insertRes = await pool.query(`
        INSERT INTO threads (group_id, author_id, content, bg_type, bg_value, likes_count)
        VALUES ($1, $2, $3, $4, $5, 0) RETURNING id
      `, [testGroupId, authorId, 'פוסט לייקים', 'color', '#000']);
      threadId = insertRes.rows[0].id;
    });

    it('should add a like, increment the count, and send a push notification', async () => {
      // משתמש אחר עושה לייק לפוסט של המחבר
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: otherUserId };
        next();
      });

      const response = await request(app).post(`/api/v1/threads/${threadId}/like`);
      expect(response.statusCode).toBe(200);
      expect(response.body.liked).toBe(true);

      // בדיקת בסיס הנתונים (המונה עלה והרשומה נוספה)
      const threadCheck = await pool.query('SELECT likes_count FROM threads WHERE id = $1', [threadId]);
      expect(parseInt(threadCheck.rows[0].likes_count, 10)).toBe(1);

      // בדיקת RabbitMQ (נשלח אירוע לתור ה-Push)
      const mockChannel = getChannel();
      expect(mockChannel.publish).toHaveBeenCalledWith(
        '',
        'push',
        expect.any(Buffer)
      );
    });

    it('should remove a like and decrement the count if clicked again', async () => {
      // עושים לייק פעם ראשונה
      await request(app).post(`/api/v1/threads/${threadId}/like`);
      
      // עושים לייק פעם שנייה (מבטל את הראשון)
      const response = await request(app).post(`/api/v1/threads/${threadId}/like`);
      expect(response.statusCode).toBe(200);
      expect(response.body.liked).toBe(false);

      const threadCheck = await pool.query('SELECT likes_count FROM threads WHERE id = $1', [threadId]);
      expect(parseInt(threadCheck.rows[0].likes_count, 10)).toBe(0);
    });
  });

  // ==========================================
  // תגובות (Comments)
  // ==========================================
  describe('POST & GET /api/v1/threads/:id/comments', () => {
    let threadId;

    beforeEach(async () => {
      const insertRes = await pool.query(`
        INSERT INTO threads (group_id, author_id, content, bg_type, bg_value, comments_count)
        VALUES ($1, $2, $3, $4, $5, 0) RETURNING id
      `, [testGroupId, authorId, 'פוסט עם תגובות', 'color', '#000']);
      threadId = insertRes.rows[0].id;
    });

    it('should add a comment, update thread count, and queue moderation', async () => {
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: otherUserId };
        next();
      });

      const commentData = { content: 'תגובה מעולה!' };
      const response = await request(app)
        .post(`/api/v1/threads/${threadId}/comments`)
        .send(commentData);

      expect(response.statusCode).toBe(201);
      expect(response.body.content).toBe(commentData.content);

      // וידוא שהמונה קפץ
      const threadCheck = await pool.query('SELECT comments_count FROM threads WHERE id = $1', [threadId]);
      expect(parseInt(threadCheck.rows[0].comments_count, 10)).toBe(1);

      // וידוא ש-RabbitMQ הופעל גם לסינון התוכן וגם להתראת ה-Push למחבר הפוסט (פעמיים בסך הכל)
      const mockChannel = getChannel();
      expect(mockChannel.publish).toHaveBeenCalledTimes(2); 
    });

    it('should delete a comment and decrement the thread count', async () => {
      // יצירת תגובה ישירות ב-DB
      const insertComment = await pool.query(`
        INSERT INTO thread_comments (thread_id, author_id, content)
        VALUES ($1, $2, $3) RETURNING id
      `, [threadId, authorId, 'תגובה זמנית']);
      const commentId = insertComment.rows[0].id;

      // עדכון השרשור להכיל תגובה אחת (כדי שהורדת המונה לא תרד למינוס)
      await pool.query('UPDATE threads SET comments_count = 1 WHERE id = $1', [threadId]);

      const response = await request(app).delete(`/api/v1/threads/${threadId}/comments/${commentId}`);
      expect(response.statusCode).toBe(204);

      const threadCheck = await pool.query('SELECT comments_count FROM threads WHERE id = $1', [threadId]);
      expect(parseInt(threadCheck.rows[0].comments_count, 10)).toBe(0);
    });

    it('should fetch comments for a thread but hide rejected ones', async () => {
      // 1. נכניס תגובה רגילה (מאושרת או ממתינה)
      await pool.query(`
        INSERT INTO thread_comments (thread_id, author_id, content, moderation_status)
        VALUES ($1, $2, $3, $4)
      `, [threadId, otherUserId, 'תגובה לגיטימית', 'pending']);

      // 2. נכניס תגובה שנפסלה על ידי מודל ה-AI
      await pool.query(`
        INSERT INTO thread_comments (thread_id, author_id, content, moderation_status)
        VALUES ($1, $2, $3, $4)
      `, [threadId, otherUserId, 'קללה או תוכן פוגעני', 'rejected']);

      const response = await request(app).get(`/api/v1/threads/${threadId}/comments`);

      expect(response.statusCode).toBe(200);
      
      // אנחנו מצפים לקבל רק תגובה אחת, כי התגובה הפוגענית סוננה בשאילתה
      expect(response.body.length).toBe(1);
      expect(response.body[0].content).toBe('תגובה לגיטימית');
    });

    it('should allow the thread author to delete someone else\'s comment', async () => {
      // משתמש אחר כותב תגובה בפוסט של המחבר הראשי (authorId)
      const insertComment = await pool.query(`
        INSERT INTO thread_comments (thread_id, author_id, content)
        VALUES ($1, $2, $3) RETURNING id
      `, [threadId, otherUserId, 'תגובה של מישהו אחר']);
      const commentId = insertComment.rows[0].id;

      // נוודא שהמשתמש המחובר כעת הוא מחבר הפוסט הראשי
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: authorId };
        next();
      });

      // מחבר הפוסט מנסה למחוק את התגובה של otherUserId
      const response = await request(app).delete(`/api/v1/threads/${threadId}/comments/${commentId}`);
      
      expect(response.statusCode).toBe(204); // מחיקה עברה בהצלחה
    });
  });
});