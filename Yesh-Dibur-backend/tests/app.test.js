// tests/app.test.js
const request = require('supertest');
const app = require('../src/app');

// אנו עוקפים את החיבור למסד הנתונים ול-Redis כדי שהאפליקציה לא תנסה להתחבר אליהם באמת
jest.mock('../src/config/db', () => ({
  pool: {
    query: jest.fn(),
    connect: jest.fn(),
  }
}));

jest.mock('../src/config/redis', () => ({
  redisClient: {
    connect: jest.fn(),
    on: jest.fn(),
  }
}));

jest.mock('../src/config/rabbitmq', () => ({
  getChannel: jest.fn(),
  connectRabbitMQ: jest.fn(),
}));

describe('App Basic Routes', () => {
  
  describe('GET /health', () => {
    it('should return status ok and a timestamp', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('404 Fallback', () => {
    it('should return 404 for an unknown route', async () => {
      const response = await request(app).get('/api/v1/unknown-route');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('not found');
    });
  });

});