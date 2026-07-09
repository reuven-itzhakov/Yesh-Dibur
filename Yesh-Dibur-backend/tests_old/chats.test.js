const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');

// ניהול המשתמש המחובר באופן דינמי
const authMiddleware = require('../src/middlewares/auth');
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    req.user = { uid: 'user_A' }; // משתמש ברירת המחדל לטסטים אלו
    next();
  });
});

describe('Chats API Integration Tests', () => {
  const userA = 'user_A';
  const userB = 'user_B';
  const hackerUser = 'user_HACKER';

  // הכנת נתוני תשתית - יצירת משתמשים כדי לעמוד באילוצי Foreign Keys
  beforeAll(async () => {
    // מחיקת נתונים ישנים כדי למנוע התנגשויות
    await pool.query('DELETE FROM messages');
    await pool.query('UPDATE conversations SET last_message_id = NULL');
    await pool.query('DELETE FROM conversations');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [userA, userB, hackerUser]);

    // הזרקת המשתמשים
    const insertUserQuery = `
      INSERT INTO users (id, name, email, birth_date, interests) 
      VALUES ($1, $2, $3, $4, $5)
    `;
    await pool.query(insertUserQuery, [userA, 'User A', 'a@test.com', new Date(), ['1', '2', '3', '4', '5']]);
    await pool.query(insertUserQuery, [userB, 'User B', 'b@test.com', new Date(), ['1', '2', '3', '4', '5']]);
    await pool.query(insertUserQuery, [hackerUser, 'Hacker', 'hacker@test.com', new Date(), ['1', '2', '3', '4', '5']]);
  });

  // ניקוי טבלאות הצ'אט לפני כל טסט
  beforeEach(async () => {
    await pool.query('DELETE FROM messages');
    await pool.query('UPDATE conversations SET last_message_id = NULL');
    await pool.query('DELETE FROM conversations');
    
    // איפוס המשתמש המחובר ל-userA
    authMiddleware.mockImplementation((req, res, next) => {
      req.user = { uid: userA };
      next();
    });
  });

  afterAll(async () => {
    await pool.query('DELETE FROM messages');
    await pool.query('UPDATE conversations SET last_message_id = NULL');
    await pool.query('DELETE FROM conversations');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [userA, userB, hackerUser]);
    await pool.end();
  });

  // ==========================================
  // POST /api/v1/chats - יצירת תיבת שיחה
  // ==========================================
  describe('POST /api/v1/chats', () => {
    it('should create a new chat between two users', async () => {
      const response = await request(app)
        .post('/api/v1/chats')
        .send({ receiver_id: userB });

      expect(response.statusCode).toBe(201);
      expect(response.body).toHaveProperty('id');
      
      // וידוא שהמזהים סודרו אלפביתית כפי שמוגדר בלוגיקה
      const expectedUser1 = [userA, userB].sort()[0];
      const expectedUser2 = [userA, userB].sort()[1];
      
      expect(response.body.user1_id).toBe(expectedUser1);
      expect(response.body.user2_id).toBe(expectedUser2);
    });

    it('should block a user from creating a chat with themselves', async () => {
      const response = await request(app)
        .post('/api/v1/chats')
        .send({ receiver_id: userA }); // שולח לעצמו

      expect(response.statusCode).toBe(400);
      expect(response.body.error).toBe('You cannot create a chat with yourself.');
    });

    it('should fail validation if receiver_id is missing', async () => {
      const response = await request(app).post('/api/v1/chats').send({});
      expect(response.statusCode).toBe(400); // Zod Validation Error
    });

    it('should gracefully handle duplicate chat creation (ON CONFLICT)', async () => {
      // יצירה ראשונה
      await request(app).post('/api/v1/chats').send({ receiver_id: userB });
      
      // יצירה שנייה של אותה שיחה
      const response = await request(app).post('/api/v1/chats').send({ receiver_id: userB });
      
      // אמור להחזיר 201 או 200 (תלוי בהגדרת הראוטר) ולעבור בהצלחה ללא קריסה של ה-DB
      expect(response.statusCode).toBe(201); 
      
      // וידוא שלא נוצרה רשומה כפולה ב-DB
      const dbCheck = await pool.query('SELECT COUNT(*) FROM conversations');
      expect(parseInt(dbCheck.rows[0].count, 10)).toBe(1);
    });
  });

  // ==========================================
  // GET /api/v1/chats/:id/messages - שליפת היסטוריית הודעות ואבטחה
  // ==========================================
  describe('GET /api/v1/chats/:id/messages', () => {
    let chatId;

    beforeEach(async () => {
      // ניצור שיחה מראש בין A ל-B
      const chatRes = await pool.query(
        'INSERT INTO conversations (user1_id, user2_id) VALUES ($1, $2) RETURNING id',
        [[userA, userB].sort()[0], [userA, userB].sort()[1]]
      );
      chatId = chatRes.rows[0].id;
    });

    it('should return messages for an authorized participant', async () => {
      // נזריק הודעה לשיחה
      await pool.query(`
        INSERT INTO messages (conversation_id, sender_id, receiver_id, content, status)
        VALUES ($1, $2, $3, $4, $5)
      `, [chatId, userA, userB, 'Hello World', 'approved']);

      const response = await request(app).get(`/api/v1/chats/${chatId}/messages`);
      
      expect(response.statusCode).toBe(200);
      expect(response.body.length).toBe(1);
      expect(response.body[0].content).toBe('Hello World');
    });

    it('should block an unauthorized user from viewing the chat (Security Check)', async () => {
      // נשנה את המשתמש המחובר לפורץ שלא קשור לשיחה
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: hackerUser };
        next();
      });

      const response = await request(app).get(`/api/v1/chats/${chatId}/messages`);
      
      expect(response.statusCode).toBe(403);
      expect(response.body.error).toBe('You are not authorized to view this chat.');
    });
  });

  // ==========================================
  // PUT Actions - אישור שיחה וסימון כנקרא
  // ==========================================
  describe('PUT /api/v1/chats/:id/approve & /read', () => {
    let chatId;

    beforeEach(async () => {
      const chatRes = await pool.query(
        'INSERT INTO conversations (user1_id, user2_id) VALUES ($1, $2) RETURNING id',
        [[userA, userB].sort()[0], [userA, userB].sort()[1]]
      );
      chatId = chatRes.rows[0].id;
    });

    it('should approve pending messages', async () => {
      // נזריק הודעה שממתינה לאישור. userA הוא המקבל (receiver).
      await pool.query(`
        INSERT INTO messages (conversation_id, sender_id, receiver_id, content, status)
        VALUES ($1, $2, $3, $4, $5)
      `, [chatId, userB, userA, 'Pending Message', 'pending_approval']);

      const response = await request(app).put(`/api/v1/chats/${chatId}/approve`);
      expect(response.statusCode).toBe(200);

      // נודא ב-DB שהסטטוס השתנה ל-approved
      const msgCheck = await pool.query('SELECT status FROM messages WHERE conversation_id = $1', [chatId]);
      expect(msgCheck.rows[0].status).toBe('approved');
    });

    it('should mark approved messages as read', async () => {
      // נזריק הודעה שאושרה
      await pool.query(`
        INSERT INTO messages (conversation_id, sender_id, receiver_id, content, status)
        VALUES ($1, $2, $3, $4, $5)
      `, [chatId, userB, userA, 'Approved Message', 'approved']);

      const response = await request(app).put(`/api/v1/chats/${chatId}/read`);
      expect(response.statusCode).toBe(200);

      // נודא ב-DB שהסטטוס השתנה ל-read
      const msgCheck = await pool.query('SELECT status FROM messages WHERE conversation_id = $1', [chatId]);
      expect(msgCheck.rows[0].status).toBe('read');
    });
  });
});