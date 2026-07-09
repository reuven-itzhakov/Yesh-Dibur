// tests/search.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');

// הגדרת Mocks
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

describe('Search API Routes (/api/v1/search)', () => {
  const mockUid = 'firebase-uid-search-1';
  const mockToken = 'Bearer valid-search-token';

  beforeEach(() => {
    jest.clearAllMocks();
    auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
  });

  describe('GET /api/v1/search', () => {
    
    it('should return 400 if validation fails (invalid type parameter)', async () => {
      const response = await request(app)
        .get('/api/v1/search?type=aliens') // סוג חיפוש שלא קיים ב-Enum
        .set('Authorization', mockToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
    });

    it('should limit pagination values to prevent DoS attacks', async () => {
      // אנחנו רוצים לוודא שהקונטרולר מגביל את ה-limit למקסימום 50 גם אם המשתמש שלח מיליון
      
      // הדמיית שאילתת בדיקת הגיל של המשתמש המחפש (חלק ראשון של ה-Service)
      pool.query.mockResolvedValueOnce({ rows: [{ age: 25, location: null }] });
      
      // הדמיית תוצאות חיפוש משתמשים
      pool.query.mockResolvedValueOnce({ rows: [] });
      
      // הדמיית תוצאות חיפוש קבוצות
      pool.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .get('/api/v1/search?limit=10000') // ניסיון לשאוב 10,000 רשומות
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.pagination.limit).toBe(50); // הקונטרולר שלנו עצר אותו והוריד ל-50!
    });

    it('should perform a successful search for users and format distance', async () => {
      // 1. שליפת גיל ומיקום של המחפש
      pool.query.mockResolvedValueOnce({ 
        rows: [{ age: 25, location: 'POINT(32.0 34.0)' }] 
      });

      // 2. תוצאות חיפוש משתמשים
      pool.query.mockResolvedValueOnce({ 
        rows: [
          { id: 'user-2', name: 'אבי', age: 26, distance_km: 0.5 },
          { id: 'user-3', name: 'דני', age: 30, distance_km: 12 }
        ] 
      });

      const response = await request(app)
        .get('/api/v1/search?type=users&q=אבי')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.data.users).toBeDefined();
      expect(response.body.data.users.length).toBe(2);
      expect(response.body.data.groups).toBeUndefined(); // ביקשנו רק users אז קבוצות לא אמורות לחזור
      
      // בדיקת הסתרת מרחק מדויק
      expect(response.body.data.users[0].distance_km).toBeUndefined();
      expect(response.body.data.users[0].location_label).toBe('קרוב אליך');
      expect(response.body.data.users[1].location_label).toBe('במרחק 12 ק"מ');
    });

    it('should enforce age restrictions for minors', async () => {
      // 1. המחפש הוא קטין בן 16
      pool.query.mockResolvedValueOnce({ rows: [{ age: 16, location: null }] });
      
      // 2. תוצאות חיפוש (מסד הנתונים מדמה תשובה כלשהי)
      pool.query.mockResolvedValueOnce({ rows: [{ id: 'user-2', name: 'קטין אחר' }] });

      await request(app)
        .get('/api/v1/search?type=users&max_age=25') // מנסה "לפרוץ" ולחפש בני 25
        .set('Authorization', mockToken);

      // אנחנו מציצים לתוך ה-Mock כדי לראות איזה ערך נשלח בפועל למסד הנתונים
      // pool.query נקרא פעם ראשונה לבדיקת גיל, ופעם שנייה לחיפוש.
      const searchCall = pool.query.mock.calls[1];
      const queryText = searchCall[0];
      const queryParams = searchCall[1];
      
      // למרות שהוא שלח max_age=25, ה-Service אמור היה להוריד את זה ל-17 בגלל שהוא קטין!
      expect(queryParams).toContain(17); 
    });

  });
});