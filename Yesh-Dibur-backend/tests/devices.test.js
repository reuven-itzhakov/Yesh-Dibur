// tests/devices.test.js
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');
const { auth } = require('../src/config/firebase');

jest.mock('../src/config/db', () => ({
  pool: { connect: jest.fn(), query: jest.fn() }
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

describe('Devices API Routes (/api/v1/devices)', () => {
  const mockUid = 'firebase-uid-device-1';
  const mockToken = 'Bearer valid-device-token';
  
  const mockClient = {
    query: jest.fn(),
    release: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    pool.connect.mockResolvedValue(mockClient);
    auth.verifyIdToken.mockResolvedValue({ uid: mockUid });
  });

  describe('POST /api/v1/devices', () => {
    it('should return 400 if FCM token or Device ID is missing', async () => {
      const response = await request(app)
        .post('/api/v1/devices')
        .set('Authorization', mockToken)
        .send({ device_id: 'iphone-12' }); // fcm_token חסר

      expect(response.status).toBe(400);
      expect(response.body.error[0].message).toBe('FCM Token is required');
    });

    it('should register a device successfully and return 200', async () => {
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 }); // מחיקת מכשירים קודמים
      mockClient.query.mockResolvedValueOnce({ rowCount: 1 }); // אכיפת מקסימום 4 מכשירים
      mockClient.query.mockResolvedValueOnce({ rows: [{ id: 1, device_id: 'dev-1' }] }); // הכנסה חדשה

      const response = await request(app)
        .post('/api/v1/devices')
        .set('Authorization', mockToken)
        .send({ device_id: 'dev-1', fcm_token: 'token-abc' });

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Device registered successfully');
      expect(mockClient.query).toHaveBeenCalledWith('COMMIT');
    });
  });

  describe('DELETE /api/v1/devices', () => {
    it('should handle Array Injection DoS protection and delete successfully', async () => {
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      // נשלח מערך במקום מחרוזת כדי לוודא שהקונטרולר יודע לחלץ את האיבר הראשון ולא קורס
      const response = await request(app)
        .delete('/api/v1/devices?device_id[]=hacked-array&device_id[]=another-string')
        .set('Authorization', mockToken);

      expect(response.status).toBe(204);
      // בדיקה שהשאילתה נשלחה עם המחרוזת הנקייה מהמערך
      expect(pool.query).toHaveBeenCalledWith(
        'DELETE FROM device_tokens WHERE user_id = $1 AND device_id = $2',
        [mockUid, 'hacked-array']
      );
    });

    it('should return 400 if device_id is totally missing or empty', async () => {
      const response = await request(app)
        .delete('/api/v1/devices?device_id=')
        .set('Authorization', mockToken);

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Valid Device ID is required');
    });
  });
});