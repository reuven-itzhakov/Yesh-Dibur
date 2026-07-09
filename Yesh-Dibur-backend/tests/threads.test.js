// tests/threads.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');
const { getChannel } = require('../src/config/rabbitmq');

// Mocks לתשתיות השונות
jest.mock('../src/config/db', () => ({
  pool: {
    connect: jest.fn(),
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

describe('Threads API Routes (/api/v1/threads)', () => {
  const mockUid = 'firebase-mock-uid-789';
  const mockToken = 'Bearer fake-valid-token';
  const mockGroupId = 'b5a2b8e3-0c4f-4d3a-8b9a-1c2d3e4f5a6b'; // UUID תקין עבור Zod
  const mockThreadId = '123e4567-e89b-12d3-a456-426614174000'; // UUID תקין
  
  const mockClient = {
    query: jest.fn(),
    release: jest.fn(),
  };

  const mockRabbitChannel = {
    publish: jest.fn(),
    assertQueue: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    pool.connect.mockResolvedValue(mockClient);
    auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
    getChannel.mockReturnValue(mockRabbitChannel);
  });

  describe('POST /api/v1/threads (Create Thread)', () => {
    const validThreadPayload = {
      group_id: mockGroupId,
      content: 'שלום לכולם! זה הפוסט הראשון שלי בקבוצה.',
      bg_type: 'color',
      bg_value: '#FF5733'
    };

    it('should return 400 if validation fails (missing content)', async () => {
      const invalidPayload = { ...validThreadPayload, content: '' };

      const response = await request(app)
        .post('/api/v1/threads')
        .set('Authorization', mockToken)
        .send(invalidPayload);

      expect(response.status).toBe(400);
      expect(response.body.error[0].message).toBe('Post content cannot be empty');
    });

    it('should return 404 if user is not a member of the group', async () => {
      // מדמים שמסד הנתונים לא מצא את המשתמש כחבר קבוצה ולכן לא החזיר שורות (rowCount: 0)
      pool.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/v1/threads')
        .set('Authorization', mockToken)
        .send(validThreadPayload);

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Group does not exist or you are not a member.');
    });

    it('should create a thread successfully, trigger AI moderation, and return 201', async () => {
      // 1. ה-INSERT של הפוסט
      pool.query.mockResolvedValueOnce({ 
        rows: [{ id: mockThreadId, ...validThreadPayload }] 
      });
      
      // 2. שליפת פרטי המחבר (שם ותמונה) כדי להוסיף לתשובה שחוזרת ללקוח
      pool.query.mockResolvedValueOnce({ 
        rows: [{ name: 'ישראל ישראלי', profile_image_url: 'http://example.com/img.jpg' }] 
      });

      const response = await request(app)
        .post('/api/v1/threads')
        .set('Authorization', mockToken)
        .send(validThreadPayload);

      expect(response.status).toBe(201);
      expect(response.body.id).toBe(mockThreadId);
      expect(response.body.author_name).toBe('ישראל ישראלי');
      
      // ווידוא שתור ה-RabbitMQ הופעל כדי לשלוח את הפוסט ל-Gemini Moderation
      expect(mockRabbitChannel.publish).toHaveBeenCalledWith(
        '', 
        'moderation', 
        expect.any(Buffer)
      );
    });
  });

  describe('POST /api/v1/threads/:id/like (Toggle Like)', () => {
    it('should return 403 if user is not authorized (not a member or thread deleted)', async () => {
      // מדמים את שאילתת בדיקת ההרשאה (Gatekeeper) כמחזירה מערך ריק
      mockClient.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post(`/api/v1/threads/${mockThreadId}/like`)
        .set('Authorization', mockToken);

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('Not authorized, not a member, or thread deleted');
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK');
    });

    it('should add a like and send push notification successfully', async () => {
      // 1. ה-Gatekeeper מוצא שהמשתמש מורשה (חבר קבוצה)
      mockClient.query.mockResolvedValueOnce({ rows: [{ '?column?': 1 }] });
      
      // 2. בדיקה האם כבר עשה לייק (מחזיר שורות ריקות, כלומר לא עשה עדיין)
      mockClient.query.mockResolvedValueOnce({ rows: [] });
      
      // 3. הוספת הלייק
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 });
      
      // 4. עדכון המונה ושליפת מזהה המחבר (כדי לשלוח לו פוש)
      mockClient.query.mockResolvedValueOnce({ 
        rows: [{ author_id: 'other-user-uid', group_id: mockGroupId }] 
      });

      const response = await request(app)
        .post(`/api/v1/threads/${mockThreadId}/like`)
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.liked).toBe(true);
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
      
      // ווידוא שתור ההתראות (Push) הופעל
      expect(mockRabbitChannel.publish).toHaveBeenCalledWith(
        '', 
        'push', 
        expect.any(Buffer)
      );
    });
  });
});