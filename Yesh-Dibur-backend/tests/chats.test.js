// tests/chats.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');

// Mocks לתשתיות
jest.mock('../src/config/db', () => ({
  pool: {
    query: jest.fn(),
  }
}));

jest.mock('../src/config/redis', () => ({
  redisClient: { connect: jest.fn(), on: jest.fn() },
  connectRedis: jest.fn(),
}));

jest.mock('../src/config/rabbitmq', () => ({
  getChannel: jest.fn(),
  connectRabbitMQ: jest.fn(),
}));

jest.mock('../src/config/firebase', () => ({
  auth: { verifyIdToken: jest.fn() }
}));

describe('Chats API Routes (/api/v1/chats)', () => {
  const mockUid = 'firebase-uid-user-1';
  const mockToken = 'Bearer valid-token-chat';
  
  beforeEach(() => {
    jest.clearAllMocks();
    auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
  });

  describe('POST /api/v1/chats (Create Chat)', () => {
    it('should return 400 if validation fails (missing receiver_id)', async () => {
      const response = await request(app)
        .post('/api/v1/chats')
        .set('Authorization', mockToken)
        .send({}); // חסר receiver_id

      expect(response.status).toBe(400);
      expect(response.body.error[0].message).toBe('Receiver ID is required');
    });

    it('should return 400 if user tries to chat with themselves', async () => {
      const response = await request(app)
        .post('/api/v1/chats')
        .set('Authorization', mockToken)
        .send({ receiver_id: mockUid }); // אותו ID

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('You cannot create a chat with yourself.');
    });

    it('should return 403 if blocked by privacy settings or age restrictions', async () => {
      // מדמים שהשאילתה שבודקת חסימות והתאמת גילאים מחזירה מערך ריק (0 שורות)
      pool.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/v1/chats')
        .set('Authorization', mockToken)
        .send({ receiver_id: 'firebase-uid-user-2' });

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('Cannot open chat due to privacy settings or age restrictions.');
    });

    it('should create a chat and return 201', async () => {
      // 1. בדיקת חסימות (מחזירה שורה אחת - מורשה)
      pool.query.mockResolvedValueOnce({ rows: [{ id: mockUid }] });
      // 2. יצירת השיחה / שליפת שיחה קיימת במידה ויש Conflict
      pool.query.mockResolvedValueOnce({ 
        rows: [{ id: 'chat-uuid-123', user1_id: mockUid, user2_id: 'firebase-uid-user-2' }] 
      });

      const response = await request(app)
        .post('/api/v1/chats')
        .set('Authorization', mockToken)
        .send({ receiver_id: 'firebase-uid-user-2' });

      expect(response.status).toBe(201);
      expect(response.body.id).toBe('chat-uuid-123');
    });
  });

  describe('GET /api/v1/chats/:id/messages (Get Chat Messages)', () => {
    const mockChatId = 'chat-uuid-123';

    it('should return 403 if user is not authorized to view the chat', async () => {
      // מדמים מצב שבו המשתמש מנסה לקרוא הודעות של שיחה שהוא לא חלק ממנה, או שהמשתמש השני חסם אותו
      pool.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get(`/api/v1/chats/${mockChatId}/messages`)
        .set('Authorization', mockToken);

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('You are not authorized to view this chat.');
    });

    it('should return messages successfully with pagination', async () => {
      // 1. ה-Gatekeeper מאשר את הגישה לשיחה
      pool.query.mockResolvedValueOnce({ rows: [{ id: mockChatId }] });
      // 2. שליפת ההודעות עצמן
      pool.query.mockResolvedValueOnce({ 
        rows: [
          { id: 'msg-1', content: 'היי!', sender_id: 'firebase-uid-user-2' },
          { id: 'msg-2', content: 'מה קורה?', sender_id: mockUid }
        ] 
      });

      const response = await request(app)
        .get(`/api/v1/chats/${mockChatId}/messages?page=1&limit=20`)
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.length).toBe(2);
      expect(response.body[0].content).toBe('היי!');
    });
  });

  describe('PUT /api/v1/chats/:id/approve (Approve Chat)', () => {
    it('should approve a chat and return 200', async () => {
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .put('/api/v1/chats/chat-uuid-123/approve')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Chat request approved successfully');
    });
  });
});