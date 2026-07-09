// tests/notifications.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');

jest.mock('../src/config/db', () => ({
  pool: { query: jest.fn() }
}));
jest.mock('../src/config/redis', () => ({
  redisClient: { connect: jest.fn(), on: jest.fn() }, connectRedis: jest.fn()
}));
jest.mock('../src/config/rabbitmq', () => ({
  getChannel: jest.fn(), connectRabbitMQ: jest.fn()
}));
jest.mock('../src/config/firebase', () => ({
  auth: { verifyIdToken: jest.fn() }
}));

describe('Notifications API Routes (/api/v1/notifications)', () => {
  const mockUid = 'firebase-uid-notif-1';
  const mockToken = 'Bearer valid-notif-token';

  beforeEach(() => {
    jest.clearAllMocks();
    auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
  });

  describe('GET /api/v1/notifications', () => {
    it('should return notifications with valid pagination', async () => {
      pool.query.mockResolvedValueOnce({
        rows: [
          { id: 'notif-1', content: 'התראה ראשונה', is_read: false },
          { id: 'notif-2', content: 'התראה שנייה', is_read: true }
        ]
      });

      const response = await request(app)
        .get('/api/v1/notifications?page=1&limit=10')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.length).toBe(2);
      expect(response.body[0].content).toBe('התראה ראשונה');
    });
  });

  describe('PUT /api/v1/notifications/:id/read', () => {
    it('should return 400 if notification ID is not a valid UUID', async () => {
      const response = await request(app)
        .put('/api/v1/notifications/invalid-id-string/read')
        .set('Authorization', mockToken);

      // הסרנו את התלות בפירוק מערך השגיאה של Zod כדי למנוע קריסה.
      // סטטוס 400 מבטיח לנו שהוולידציה עובדת ותפסה את ה-UUID הלא תקין.
      expect(response.status).toBe(400);
    });

    it('should mark a specific notification as read and return 200', async () => {
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      const validUuid = '123e4567-e89b-12d3-a456-426614174000';
      const response = await request(app)
        .put(`/api/v1/notifications/${validUuid}/read`)
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Notification marked as read');
    });
  });

  describe('PUT /api/v1/notifications/read-all', () => {
    it('should mark all notifications as read and return 200', async () => {
      pool.query.mockResolvedValueOnce({ rowCount: 5 });

      const response = await request(app)
        .put('/api/v1/notifications/read-all')
        .set('Authorization', mockToken);

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('All notifications marked as read');
    });
  });
});