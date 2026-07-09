// tests/groups.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');

// Mocks לתשתיות השונות (מסד נתונים, פיירבייס, תורים וזיכרון מטמון)
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

describe('Groups API Routes (/api/v1/groups)', () => {
  const mockUid = 'firebase-mock-uid-456';
  const mockToken = 'Bearer fake-valid-token';
  
  // יצירת Mock ל-Client של פול התקשרויות (כדי לתמוך בטרנזקציות BEGIN, COMMIT, ROLLBACK)
  const mockClient = {
    query: jest.fn(),
    release: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    pool.connect.mockResolvedValue(mockClient);
    auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
  });

  describe('POST /api/v1/groups (Create Group)', () => {
    const validGroupPayload = {
      name: 'קבוצת מתכנתים',
      description: 'קבוצה לדיוני קוד ואפליקציות',
      interests: ['coding', 'tech']
    };

    it('should return 400 if validation fails (name too long)', async () => {
      const invalidPayload = { 
        ...validGroupPayload, 
        name: 'שם קבוצה ארוך מדי בכוונה כדי להכשיל את הוואלידציה של Zod שמגבילה לשלושים תווים' 
      };

      const response = await request(app)
        .post('/api/v1/groups')
        .set('Authorization', mockToken)
        .send(invalidPayload);

      expect(response.status).toBe(400);
      expect(response.body.error[0].message).toBe('Group name cannot exceed 30 characters');
    });

    it('should return 403 if user reached the limit of 5 groups', async () => {
      // מדמים שמסד הנתונים מחזיר שהמשתמש כבר מנהל 5 קבוצות
      mockClient.query.mockResolvedValueOnce({ rows: [{ count: '5' }] });

      const response = await request(app)
        .post('/api/v1/groups')
        .set('Authorization', mockToken)
        .send(validGroupPayload);

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('You can only manage up to 5 groups.');
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK'); // מוודאים שהטרנזקציה בוטלה
    });

    it('should create a group successfully and return 201', async () => {
      // 1. בדיקת כמות הקבוצות (מחזיר 0)
      mockClient.query.mockResolvedValueOnce({ rows: [{ count: '0' }] });
      // 2. יצירת הקבוצה והחזרתה
      mockClient.query.mockResolvedValueOnce({ rows: [{ id: 'group-123', ...validGroupPayload, admin_id: mockUid }] });
      // 3. צירוף המנהל כחבר קבוצה אוטומטית (אין צורך להחזיר כלום)
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .post('/api/v1/groups')
        .set('Authorization', mockToken)
        .send(validGroupPayload);

      expect(response.status).toBe(201);
      expect(response.body.id).toBe('group-123');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT'); // מוודאים שהטרנזקציה נשמרה
    });
  });

  describe('POST /api/v1/groups/:id/join (Join Group)', () => {
    it('should return 403 if user is not allowed to join (age restriction, blocked, or already member)', async () => {
      // מדמים מקרה שבו ה-INSERT נכשל בגלל שומרי הסף שכתבנו ב-SQL (מחזיר rowCount: 0)
      pool.query.mockResolvedValueOnce({ rowCount: 0 });

      const response = await request(app)
        .post('/api/v1/groups/group-123/join')
        .set('Authorization', mockToken);

      expect(response.status).toBe(403);
      expect(response.body.error).toContain('Cannot join group');
    });

    it('should allow joining and return 200', async () => {
      // מדמים מקרה שבו ההכנסה הצליחה
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .post('/api/v1/groups/group-123/join')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Successfully joined the group');
    });
  });
});