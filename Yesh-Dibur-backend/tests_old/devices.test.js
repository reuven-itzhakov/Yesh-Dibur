require('dotenv').config();
const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');

// חיקוי (Mock) מערכת ההזדהות
const authMiddleware = require('../src/middlewares/auth');
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    req.user = { uid: 'user_device_test' }; 
    next();
  });
});

describe('Devices API Integration Tests', () => {
  const testUser = 'user_device_test';

  beforeAll(async () => {
    // 1. ניקוי טבלאות למניעת התנגשויות מריצות קודמות
    await pool.query('DELETE FROM device_tokens');
    await pool.query('DELETE FROM users WHERE id = $1', [testUser]);

    // 2. הזרקת משתמש בדיקה כדי לעמוד באילוץ Foreign Key
    const insertUser = `INSERT INTO users (id, name, email, birth_date) VALUES ($1, $2, $3, $4)`;
    await pool.query(insertUser, [testUser, 'Device User', 'device@test.com', new Date()]);
  });

  beforeEach(async () => {
    // מחיקת הטוקנים לפני כל טסט
    await pool.query('DELETE FROM device_tokens');
    
    authMiddleware.mockImplementation((req, res, next) => { 
      req.user = { uid: testUser }; 
      next(); 
    });
  });

  afterAll(async () => {
    // ניקוי סופי בסיום הטסטים
    await pool.query('DELETE FROM device_tokens');
    await pool.query('DELETE FROM users WHERE id = $1', [testUser]);
    await pool.end();
  });

  // ==========================================
  // POST /api/v1/devices - רישום ועדכון מכשיר
  // ==========================================
  describe('POST /api/v1/devices', () => {
    it('should register a new device token successfully', async () => {
      const payload = {
        device_id: 'device_123',
        fcm_token: 'token_abc123'
      };

      const response = await request(app).post('/api/v1/devices').send(payload);
      
      expect(response.statusCode).toBe(200);
      expect(response.body.message).toBe('Device registered successfully');

      // וידוא שהנתונים נשמרו ב-DB
      const dbCheck = await pool.query('SELECT * FROM device_tokens WHERE user_id = $1 AND device_id = $2', [testUser, payload.device_id]);
      expect(dbCheck.rows.length).toBe(1);
      expect(dbCheck.rows[0].fcm_token).toBe(payload.fcm_token);
    });

    it('should update the fcm_token if the device_id already exists (UPSERT)', async () => {
      const deviceId = 'device_456';
      
      // 1. הלקוח מתחבר פעם ראשונה
      await request(app).post('/api/v1/devices').send({
        device_id: deviceId,
        fcm_token: 'old_token_111'
      });

      // 2. פיירבייס יצר טוקן חדש למכשיר, הלקוח שולח בקשה נוספת עם אותו מזהה מכשיר
      const response = await request(app).post('/api/v1/devices').send({
        device_id: deviceId,
        fcm_token: 'new_token_222'
      });

      // 3. נוודא שהבקשה הצליחה ולא קרסה בגלל כפילות
      expect(response.statusCode).toBe(200);

      const dbCheck = await pool.query('SELECT * FROM device_tokens WHERE user_id = $1 AND device_id = $2', [testUser, deviceId]);
      expect(dbCheck.rows.length).toBe(1); // לא נוצרה רשומה כפולה
      expect(dbCheck.rows[0].fcm_token).toBe('new_token_222'); // הטוקן התעדכן בהצלחה
    });

    it('should fail validation if required fields are missing', async () => {
      // שליחת נתונים חסרים (Zod Validation אמור לחסום)
      const response = await request(app).post('/api/v1/devices').send({
        device_id: 'only_device_id' // חסר fcm_token
      });

      expect(response.statusCode).toBe(400);
    });
  });

  // ==========================================
  // DELETE /api/v1/devices - מחיקת מכשיר
  // ==========================================
  describe('DELETE /api/v1/devices', () => {
    it('should remove a device token successfully', async () => {
      const deviceId = 'device_789';
      
      // הזרקת המכשיר ל-DB
      await pool.query(`
        INSERT INTO device_tokens (user_id, device_id, fcm_token) 
        VALUES ($1, $2, $3)
      `, [testUser, deviceId, 'some_token']);

      // קריאה למחיקה (הערך נשלח דרך ה-Query Parameters כפי שמוגדר ב-Controller)
      const response = await request(app).delete(`/api/v1/devices?device_id=${deviceId}`);
      
      expect(response.statusCode).toBe(204);

      // וידוא שהרשומה נמחקה
      const dbCheck = await pool.query('SELECT * FROM device_tokens WHERE user_id = $1 AND device_id = $2', [testUser, deviceId]);
      expect(dbCheck.rows.length).toBe(0);
    });

    it('should return 400 if device_id is missing from the query', async () => {
      const response = await request(app).delete('/api/v1/devices'); // לא צורף device_id
      
      expect(response.statusCode).toBe(400);
      expect(response.body.error).toBe('Device ID is required');
    });
  });
});