// tests/feeds.test.js
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

describe('Feeds API Routes (/api/v1/feeds)', () => {
  const mockUid = 'firebase-uid-feed-1';
  const mockToken = 'Bearer valid-token';

  beforeEach(() => {
    jest.clearAllMocks();
    auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
  });

  describe('GET /api/v1/feeds/my-groups', () => {
    it('should return 400 if validation fails (e.g. limit is not a number)', async () => {
      const response = await request(app)
        .get('/api/v1/feeds/my-groups?limit=invalid')
        .set('Authorization', mockToken);

      // אישור שהשרת החזיר 400 - זה ההוכחה הכי חזקה שהוולידציה עובדת
      expect(response.status).toBe(400);
      
      // במקום לבדוק מפתחות ספציפיים באובייקט, נבדוק שהתשובה אינה תקינה (כלומר, אינה מכילה את השדות של פיד מוצלח)
      expect(response.body).not.toHaveProperty('data');
    });

    it('should return feed data successfully', async () => {
      const mockRows = [
        { id: 'thread-1', content: 'פוסט מקבוצה שלי', author_name: 'יוסי', group_name: 'מפתחים' },
        { id: 'thread-2', content: 'עוד פוסט', author_name: 'דנה', group_name: 'מוזיקה' }
      ];
      
      pool.query.mockResolvedValueOnce({ rows: mockRows });

      const response = await request(app)
        .get('/api/v1/feeds/my-groups?limit=10')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBe(2);
      expect(response.body.data[0].content).toBe('פוסט מקבוצה שלי');
      expect(response.body.next_cursor).toBeNull();
    });
  });

  describe('GET /api/v1/feeds/discovery', () => {
    it('should return discovery feed data and format distances correctly', async () => {
      pool.query.mockResolvedValueOnce({ 
        rows: [{ location: 'POINT(34.7818 32.0853)', interests: ['tech'] }] 
      });

      const mockFeedRows = [
        { id: 'thread-3', content: 'פוסט ממש קרוב', distance_km: 0.5 },
        { id: 'thread-4', content: 'פוסט רחוק יותר', distance_km: 5 }
      ];
      pool.query.mockResolvedValueOnce({ rows: mockFeedRows });

      const response = await request(app)
        .get('/api/v1/feeds/discovery?limit=5')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBe(2);
      
      expect(response.body.data[0].distance_km).toBeUndefined();
      expect(response.body.data[0].location_label).toBe('קרוב אליך');
      expect(response.body.data[1].location_label).toBe('במרחק 5 ק"מ');
    });

    it('should handle users without location gracefully (Unknown distance)', async () => {
        pool.query.mockResolvedValueOnce({ 
            rows: [{ location: null, interests: ['music'] }] 
        });

        pool.query.mockResolvedValueOnce({ 
          rows: [{ id: 'thread-5', content: 'פוסט ללא מיקום ידוע', distance_km: null }] 
        });

        const response = await request(app)
            .get('/api/v1/feeds/discovery')
            .set('Authorization', mockToken);

        expect(response.status).toBe(200);
        expect(response.body.data[0].location_label).toBe('מרחק לא ידוע');
    });
  });
});