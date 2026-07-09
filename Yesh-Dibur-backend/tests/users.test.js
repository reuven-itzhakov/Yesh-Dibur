// tests/users.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');

// הגדרת Mocks לתשתיות
jest.mock('../src/config/db', () => ({
  pool: {
    query: jest.fn(),
  },
  connectDB: jest.fn(),
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
  auth: {
    verifyIdToken: jest.fn(),
  },
  messaging: {},
}));

describe('Users API Routes (/api/v1/users)', () => {
  const mockUid = 'firebase-mock-uid-123';
  const mockToken = 'Bearer fake-valid-token';

  beforeEach(() => {
    // ניקוי המצביעים לפני כל טסט כדי שמידע לא יזלוג מבדק לבדק
    jest.clearAllMocks();
  });

  describe('POST /api/v1/users/register', () => {
    const validPayload = {
      name: 'ישראל ישראלי',
      email: 'israel@example.com',
      phone: '0501234567',
      birth_date: '1990-01-01T00:00:00Z',
      interests: ['tech', 'coding', 'music', 'gaming', 'sports'], // חובה בדיוק 5 לפי הסכמה
    };

    it('should return 401 if no token is provided', async () => {
      const response = await request(app)
        .post('/api/v1/users/register')
        .send(validPayload);
      
      expect(response.status).toBe(401);
      expect(response.body.error).toBe('No token provided');
    });

    it('should return 400 if validation fails (e.g., missing interests)', async () => {
      auth.verifyIdToken.mockResolvedValue({ uid: mockUid });

      const invalidPayload = { ...validPayload, interests: ['tech'] }; // רק תחום אחד במקום 5

      const response = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', mockToken)
        .send(invalidPayload);

      // מסתמכים על סטטוס 400 במקום לפרק את אובייקט ה-Zod
      expect(response.status).toBe(400);
    });

    it('should register a user successfully and return 201', async () => {
      // הדמיית אישור טוקן מול פיירבייס
      auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
      
      // הדמיית תשובה מוצלחת מהמסד (PostgreSQL)
      pool.query.mockResolvedValueOnce({
        rows: [{ id: mockUid, ...validPayload }],
      });

      const response = await request(app)
        .post('/api/v1/users/register')
        .set('Authorization', mockToken)
        .send(validPayload);

      expect(response.status).toBe(201);
      expect(response.body.id).toBe(mockUid);
      expect(pool.query).toHaveBeenCalledTimes(1);
    });
  });

  describe('GET /api/v1/users/profile', () => {
    it('should return 404 if user profile is not found in DB', async () => {
      auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
      
      // הדמיית מצב שבו המשתמש מחוק או לא קיים (מערך שורות ריק)
      pool.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', mockToken);

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('User profile not found');
    });

    it('should return user profile successfully', async () => {
      auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
      
      const mockUser = { id: mockUid, name: 'ישראל ישראלי', email: 'israel@example.com' };
      pool.query.mockResolvedValueOnce({ rows: [mockUser] });

      const response = await request(app)
        .get('/api/v1/users/profile')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.name).toBe('ישראל ישראלי');
    });
  });
});