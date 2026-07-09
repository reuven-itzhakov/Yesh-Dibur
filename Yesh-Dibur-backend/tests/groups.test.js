// tests/groups.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');

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

describe('Groups API Routes (/api/v1/groups)', () => {
  const mockUid = 'firebase-mock-uid-456';
  const mockToken = 'Bearer fake-valid-token';
  
  // יצירת Mock ל-Client של פול התקשרויות
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

      // מסתמכים על סטטוס 400 כדי לא לקרוס על מבנה אובייקט ה-Zod
      expect(response.status).toBe(400);
    });

    it('should return 403 if user reached the limit of 5 groups', async () => {
      // מספקים תשובות עבור: BEGIN, ואז לבדיקת ה-COUNT, ואז ל-ROLLBACK שקורה במקרה של כישלון
      mockClient.query
        .mockResolvedValueOnce({}) // 1. BEGIN
        .mockResolvedValueOnce({ rows: [{ count: '5' }] }) // 2. SELECT COUNT
        .mockResolvedValueOnce({}); // 3. ROLLBACK (inside catch)

      const response = await request(app)
        .post('/api/v1/groups')
        .set('Authorization', mockToken)
        .send(validGroupPayload);

      expect(response.status).toBe(403);
      expect(response.body.error).toBe('You can only manage up to 5 groups.');
      expect(mockClient.query).toHaveBeenCalledWith('ROLLBACK'); 
    });

    it('should create a group successfully and return 201', async () => {
      // מספקים תשובות עבור כל שלבי הטרנזקציה לפי הסדר
      mockClient.query
        .mockResolvedValueOnce({}) // 1. BEGIN
        .mockResolvedValueOnce({ rows: [{ count: '0' }] }) // 2. SELECT COUNT
        .mockResolvedValueOnce({ rows: [{ id: 'group-123', ...validGroupPayload, admin_id: mockUid }] }) // 3. INSERT group
        .mockResolvedValueOnce({ rowCount: 1 }) // 4. INSERT group_members
        .mockResolvedValueOnce({}); // 5. COMMIT

      const response = await request(app)
        .post('/api/v1/groups')
        .set('Authorization', mockToken)
        .send(validGroupPayload);

      expect(response.status).toBe(201);
      expect(response.body.id).toBe('group-123');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
    });
  });

  describe('POST /api/v1/groups/:id/join (Join Group)', () => {
    it('should return 403 if user is not allowed to join (age restriction, blocked, or already member)', async () => {
      pool.query.mockResolvedValueOnce({ rowCount: 0 });

      const response = await request(app)
        .post('/api/v1/groups/group-123/join')
        .set('Authorization', mockToken);

      expect(response.status).toBe(403);
      expect(response.body.error).toContain('Cannot join group');
    });

    it('should allow joining and return 200', async () => {
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      const response = await request(app)
        .post('/api/v1/groups/group-123/join')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Successfully joined the group');
    });
  });
});