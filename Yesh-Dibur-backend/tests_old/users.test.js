const request = require('supertest');
const app = require('../src/app'); // נתיב יחסי ל-app.js שלך
const { pool } = require('../src/config/db'); // ייבוא ה-pool כדי לבדוק את ה-DB בסוף
const authMiddleware = require('../src/middlewares/auth');

// 1. Mocking ל-Middleware של האימות (Authentication)
// נניח שהנתיב של המידלוור הוא '../src/middlewares/auth'
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    // מצב ברירת המחדל לרוב הטסטים (משתמש מחובר)
    req.user = { uid: 'firebase_test_uid_123' };
    next();
  });
});

// 2. Mocking למימדי תשתית אחרים אם ה-app.js מפעיל אותם בעקיפין
// (למשל, אם ה-rateLimiter משתמש ב-Redis והוא עלול לתקוע את הטסט)
jest.mock('../src/middlewares/rateLimiter', () => (req, res, next) => next());

describe('Users API Integration Tests', () => {
  
  // לפני הכל: נרצה לוודא שבסיס הנתונים של הבדיקות נקי מהמשתמש הפיקטיבי שלנו
  beforeEach(async () => {
    await pool.query('DELETE FROM users WHERE id = $1', ['firebase_test_uid_123']);
  });

  // בסיום כל הטסטים: נסגור את ה-Pool כדי ש-Jest יוכל לסיים את הריצה בהצלחה
  afterAll(async () => {
    await pool.end();
  });

  describe('POST /api/v1/users/register', () => {
    it('should register a new user and save it in PostgreSQL', async () => {
      // נתוני קלט תקינים לפי ה-Zod Schema שלך (כולל בדיוק 5 תחומי עניין)
      const validUserData = {
        name: 'ישראל ישראלי',
        email: 'test@example.com',
        phone: '0501234567',
        birth_date: new Date().toISOString(),
        city: 'תל אביב',
        bio: 'מפתח תוכנה צעיר',
        interests: ['ספורט', 'מוזיקה', 'טכנולוגיה', 'סרטים', 'בישול'],
        location: { lng: 34.7818, lat: 32.0853 } // נתוני PostGIS למרכז ת"א
      };

      // א. שליחת הבקשה ל-endpoint באמצעות Supertest
      const response = await request(app)
        .post('/api/v1/users/register')
        .send(validUserData);

      // ב. בדיקת תגובת ה-API הנהדרת שחוזרת (Controller -> Service)
      expect(response.statusCode).toBe(201);
      expect(response.body).toHaveProperty('id', 'firebase_test_uid_123');
      expect(response.body.name).toBe(validUserData.name);

      // ג. הבדיקה החשובה ביותר: שאילתה ישירה ל-DB לוודא שהרשומה נוצרה פיזית
      const dbResult = await pool.query('SELECT * FROM users WHERE id = $1', ['firebase_test_uid_123']);
      
      expect(dbResult.rows.length).toBe(1);
      expect(dbResult.rows[0].email).toBe(validUserData.email);
      expect(dbResult.rows[0].name).toBe(validUserData.name);
    });

    it('should fail validation if interests array does not have exactly 5 items', async () => {
      const invalidUserData = {
        name: 'משה',
        email: 'moshe@example.com',
        phone: '0501111111',
        birth_date: new Date().toISOString(),
        city: 'חיפה',
        interests: ['רק אחד'] // פחות מ-5, ה-Zod יכשיל את זה
      };

      const response = await request(app)
        .post('/api/v1/users/register')
        .send(invalidUserData);

      // כאן הסטטוס קוד תלוי באיך ה-errorHandler הגלובלי שלך מטפל בשגיאות Zod
      // בדרך כלל שגיאות וולידציה מחזירות 400 Bad Request
      expect(response.statusCode).toBe(400); 
    });

    it('should fail validation if required fields are missing', async () => {
      const invalidUserData = {
        // חסרים שדות חובה כמו name ו-email
        phone: '0501234567',
        interests: ['א', 'ב', 'ג', 'ד', 'ה']
      };

      const response = await request(app)
        .post('/api/v1/users/register')
        .send(invalidUserData);

      expect(response.statusCode).toBe(400); 
    });

    it('should handle duplicate user registration gracefully (same UID)', async () => {
      const userData = {
        name: 'משתמש ראשון',
        email: 'first@example.com',
        phone: '0500000000',
        birth_date: new Date().toISOString(),
        city: 'תל אביב',
        interests: ['1', '2', '3', '4', '5']
      };

      // 1. נרשמים פעם אחת בהצלחה
      await request(app).post('/api/v1/users/register').send(userData);

      // 2. מנסים להירשם שוב עם אותו Firebase UID (שהוגדר ב-Mock)
      const duplicateResponse = await request(app)
        .post('/api/v1/users/register')
        .send(userData);

      // הסטטוס קוד כאן תלוי באיך שאתה מטפל בשגיאות Database (בדרך כלל 400 או 409)
      expect(duplicateResponse.statusCode).not.toBe(201); 
    });
  });

  describe('GET /api/v1/users/profile', () => {
    it('should return 404 if the profile does not exist', async () => {
      const response = await request(app).get('/api/v1/users/profile');
      expect(response.statusCode).toBe(404);
    });

    it('should fetch the correct profile after it has been created', async () => {
      // 1. נכניס ידנית משתמש ל-DB (או שנשתמש ב-Service) כדי להכין את המצב הנדרש
      await pool.query(`
        INSERT INTO users (id, name, email, phone, birth_date, interests) 
        VALUES ($1, $2, $3, $4, $5, $6)
      `, ['firebase_test_uid_123', 'יוסי', 'yossi@test.com', '0522222222', new Date(), ['א', 'ב', 'ג', 'ד', 'ה']]);

      // 2. ננסה לשלוף את הפרופיל דרך ה-API
      const response = await request(app).get('/api/v1/users/profile');

      expect(response.statusCode).toBe(200);
      expect(response.body.name).toBe('יוסי');
      expect(response.body.email).toBe('yossi@test.com');
    });
  });

  describe('PUT /api/v1/users/profile', () => {
    it('should dynamically update only the provided fields', async () => {
      // הכנת משתמש קיים
      await pool.query(`
        INSERT INTO users (id, name, email, phone, birth_date, interests, bio) 
        VALUES ($1, $2, $3, $4, $5, $6, $7)
      `, ['firebase_test_uid_123', 'יוסי', 'yossi@test.com', '0522222222', new Date(), ['א', 'ב', 'ג', 'ד', 'ה'], 'ביו ישן']);

      // עדכון ה-Bio בלבד
      const response = await request(app)
        .put('/api/v1/users/profile')
        .send({ bio: 'ביו חדש ומעודכן!' });

      expect(response.statusCode).toBe(200);
      expect(response.body.bio).toBe('ביו חדש ומעודכן!');
      expect(response.body.name).toBe('יוסי'); // נשאר ללא שינוי

      // וידוא מול ה-DB
      const dbResult = await pool.query('SELECT bio FROM users WHERE id = $1', ['firebase_test_uid_123']);
      expect(dbResult.rows[0].bio).toBe('ביו חדש ומעודכן!');
    });

    it('should return 400 if social URLs are invalid', async () => {
      await pool.query(`
        INSERT INTO users (id, name, email, phone, birth_date, interests) 
        VALUES ($1, $2, $3, $4, $5, $6)
      `, ['firebase_test_uid_123', 'יוסי', 'yossi@test.com', '0522222222', new Date(), ['א', 'ב', 'ג', 'ד', 'ה']]);

      const response = await request(app)
        .put('/api/v1/users/profile')
        .send({ instagram_url: 'not-a-valid-url' }); // Zod אמור לחסום את זה

      expect(response.statusCode).toBe(400);
    });

    it('should ignore restricted fields if user tries to update them', async () => {
      await pool.query(`
        INSERT INTO users (id, name, email, phone, birth_date, interests) 
        VALUES ($1, $2, $3, $4, $5, $6)
      `, ['firebase_test_uid_123', 'יוסי', 'yossi@test.com', '0522222222', new Date(), ['א', 'ב', 'ג', 'ד', 'ה']]);

      // הלקוח מנסה להיות חכם ולשנות לעצמו את ה-ID או את האימייל
      const response = await request(app)
        .put('/api/v1/users/profile')
        .send({ 
          id: 'hacker_new_id', 
          email: 'hacker@test.com',
          name: 'יוסי המעודכן' 
        });

      expect(response.statusCode).toBe(200);
      expect(response.body.name).toBe('יוסי המעודכן'); // השדה המותר עודכן
      
      // וידוא שהאימייל לא השתנה ב-DB
      const dbResult = await pool.query('SELECT email, id FROM users WHERE id = $1', ['firebase_test_uid_123']);
      expect(dbResult.rows[0].email).toBe('yossi@test.com');
    });
  });

  describe('DELETE /api/v1/users/profile', () => {
    it('should perform a soft delete by setting deleted_at timestamp', async () => {
      await pool.query(`
        INSERT INTO users (id, name, email, phone, birth_date, interests) 
        VALUES ($1, $2, $3, $4, $5, $6)
      `, ['firebase_test_uid_123', 'יוסי', 'yossi@test.com', '0522222222', new Date(), ['א', 'ב', 'ג', 'ד', 'ה']]);

      const response = await request(app).delete('/api/v1/users/profile');
      expect(response.statusCode).toBe(204); // Success, No Content

      // וידוא שהמשתמש עדיין קיים ב-DB אבל שדה deleted_at אינו ריק (Soft Delete)
      const dbResult = await pool.query('SELECT deleted_at FROM users WHERE id = $1', ['firebase_test_uid_123']);
      expect(dbResult.rows[0].deleted_at).not.toBeNull();
    });
  });

  describe('Authentication & Security', () => {
    it('should return 401 Unauthorized if no valid token is provided', async () => {
      // אנחנו משנים את ההתנהגות של ה-Mock באופן חד פעמי רק עבור הטסט הזה
      authMiddleware.mockImplementationOnce((req, res, next) => {
        res.status(401).json({ error: 'Unauthorized' });
      });

      const response = await request(app).get('/api/v1/users/profile');
      expect(response.statusCode).toBe(401);
    });
  });

  describe('GET /api/v1/users/:id (Public Profile)', () => {
    it('should return a public profile without sensitive fields like email and phone', async () => {
      // נכניס משתמש נוסף ל-DB, שאותו המשתמש שלנו ינסה לשלוף
      const targetUserId = 'target_user_456';

      // מחיקת המשתמש במידה והוא נשאר שם מהרצה קודמת
      await pool.query('DELETE FROM users WHERE id = $1', [targetUserId]);

      await pool.query(`
        INSERT INTO users (id, name, email, phone, birth_date, interests, bio) 
        VALUES ($1, $2, $3, $4, $5, $6, $7)
      `, [targetUserId, 'דני', 'danny@private.com', '0509999999', new Date(), ['א', 'ב', 'ג', 'ד', 'ה'], 'פרופיל ציבורי']);

      // פנייה ל-endpoint של הפרופיל הציבורי
      const response = await request(app).get(`/api/v1/users/${targetUserId}`);

      expect(response.statusCode).toBe(200);
      expect(response.body.name).toBe('דני');
      expect(response.body.bio).toBe('פרופיל ציבורי');
      
      // הבדיקות החשובות ביותר לאבטחת מידע
      expect(response.body).not.toHaveProperty('email');
      expect(response.body).not.toHaveProperty('phone');
      expect(response.body).not.toHaveProperty('location'); // אם הגדרת שמיקום מדויק הוא רגיש
    });
  });
});