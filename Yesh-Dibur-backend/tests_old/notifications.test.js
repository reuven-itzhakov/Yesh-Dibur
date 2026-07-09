const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');

// חיקוי הזדהות
const authMiddleware = require('../src/middlewares/auth');
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    req.user = { uid: 'user_main' }; 
    next();
  });
});

describe('Notifications API Integration Tests', () => {
  const userMain = 'user_main';
  const userSender = 'user_sender';
  const userHacker = 'user_hacker';

  beforeAll(async () => {
    // 1. ניקוי הטבלאות
    await pool.query('DELETE FROM notifications');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [userMain, userSender, userHacker]);

    // 2. יצירת משתמשים (כולל שולח ההתראה כדי לבדוק את ה-JOIN)
    const insertUser = `INSERT INTO users (id, name, email, birth_date) VALUES ($1, $2, $3, $4)`;
    await pool.query(insertUser, [userMain, 'Main User', 'main@test.com', new Date()]);
    await pool.query(insertUser, [userSender, 'Sender User', 'sender@test.com', new Date()]);
    await pool.query(insertUser, [userHacker, 'Hacker User', 'hacker@test.com', new Date()]);
  });

  beforeEach(async () => {
    // מחיקת ההתראות לפני כל טסט כדי להתחיל נקי
    await pool.query('DELETE FROM notifications');
    
    // איפוס המשתמש המחובר חזרה למשתמש הראשי
    authMiddleware.mockImplementation((req, res, next) => { 
      req.user = { uid: userMain }; 
      next(); 
    });
  });

  afterAll(async () => {
    await pool.query('DELETE FROM notifications');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [userMain, userSender, userHacker]);
    await pool.end();
  });

  // פונקציית עזר להזרקת התראות למסד הנתונים
  const insertNotification = async (userId, senderId, isRead = false) => {
    const res = await pool.query(`
      INSERT INTO notifications (user_id, sender_id, type, content, is_read)
      VALUES ($1, $2, 'like', 'Someone liked your post', $3) RETURNING id, created_at
    `, [userId, senderId, isRead]);
    return res.rows[0];
  };

  // ==========================================
  // GET /api/v1/notifications
  // ==========================================
  describe('GET /api/v1/notifications', () => {
    it('should fetch notifications with sender details', async () => {
      await insertNotification(userMain, userSender, false);

      const response = await request(app).get('/api/v1/notifications');
      
      expect(response.statusCode).toBe(200);
      expect(response.body.length).toBe(1);
      
      // מוודאים שה-JOIN עבד והביא את שם השולח מטבלת users
      expect(response.body[0].sender_name).toBe('Sender User');
      expect(response.body[0].is_read).toBe(false);
    });

    it('should paginate correctly using limit and offset (page)', async () => {
      // נכניס 3 התראות בזמנים שונים
      for (let i = 0; i < 3; i++) {
        await insertNotification(userMain, userSender, false);
        await new Promise(r => setTimeout(r, 50)); // השהייה ליצירת סדר יורד מדויק
      }

      // נבקש את העמוד הראשון עם הגבלה של 2 התראות
      const page1 = await request(app).get('/api/v1/notifications?limit=2&page=1');
      expect(page1.statusCode).toBe(200);
      expect(page1.body.length).toBe(2);

      // נבקש את העמוד השני עם אותה הגבלה
      const page2 = await request(app).get('/api/v1/notifications?limit=2&page=2');
      expect(page2.statusCode).toBe(200);
      expect(page2.body.length).toBe(1); // נשארה רק התראה אחת
      
      // מוודאים שאין כפילות בין העמודים
      expect(page1.body[0].id).not.toBe(page2.body[0].id);
      expect(page1.body[1].id).not.toBe(page2.body[0].id);
    });

    it('should not expose notifications belonging to other users', async () => {
      // מכניסים התראה למשתמש אחר
      await insertNotification(userHacker, userSender, false);

      const response = await request(app).get('/api/v1/notifications');
      expect(response.statusCode).toBe(200);
      expect(response.body.length).toBe(0); // המשתמש הראשי לא רואה אותה
    });
  });

  // ==========================================
  // PUT /api/v1/notifications/:id/read
  // ==========================================
  describe('PUT /api/v1/notifications/:id/read', () => {
    it('should mark a specific notification as read', async () => {
      const notif = await insertNotification(userMain, userSender, false);

      const response = await request(app).put(`/api/v1/notifications/${notif.id}/read`);
      expect(response.statusCode).toBe(200);
      expect(response.body.message).toBe('Notification marked as read');

      // נוודא במסד הנתונים
      const dbCheck = await pool.query('SELECT is_read FROM notifications WHERE id = $1', [notif.id]);
      expect(dbCheck.rows[0].is_read).toBe(true);
    });

    it('should quietly ignore if an unauthorized user tries to read someone else\'s notification', async () => {
      // התראה ששייכת למשתמש הראשי
      const notif = await insertNotification(userMain, userSender, false);

      // פורץ מנסה לסמן אותה כנקראה
      authMiddleware.mockImplementationOnce((req, res, next) => { 
        req.user = { uid: userHacker }; 
        next(); 
      });

      const response = await request(app).put(`/api/v1/notifications/${notif.id}/read`);
      
      // למרות שה-API מחזיר 200 (בגלל שהשירות לא זורק שגיאה אם הרשומה לא עודכנה),
      // חובה עלינו לוודא שהסטטוס ב-DB *לא* השתנה.
      expect(response.statusCode).toBe(200);

      const dbCheck = await pool.query('SELECT is_read FROM notifications WHERE id = $1', [notif.id]);
      expect(dbCheck.rows[0].is_read).toBe(false); // הסטטוס נשאר false!
    });
  });

  // ==========================================
  // PUT /api/v1/notifications/read-all
  // ==========================================
  describe('PUT /api/v1/notifications/read-all', () => {
    it('should mark all unread notifications of the user as read', async () => {
      // מכניסים 2 התראות שלא נקראו
      await insertNotification(userMain, userSender, false);
      await insertNotification(userMain, userSender, false);

      const response = await request(app).put('/api/v1/notifications/read-all');
      expect(response.statusCode).toBe(200);

      const dbCheck = await pool.query('SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false', [userMain]);
      expect(parseInt(dbCheck.rows[0].count, 10)).toBe(0); // מוודאים שלא נותרו התראות שלא נקראו
    });

    it('should not mark notifications of other users as read', async () => {
      // התראה למשתמש אחר
      const otherNotif = await insertNotification(userHacker, userSender, false);

      // המשתמש הראשי מסמן את הכל כנקרא
      await request(app).put('/api/v1/notifications/read-all');

      // נוודא שההתראה של המשתמש האחר עדיין 'false'
      const dbCheck = await pool.query('SELECT is_read FROM notifications WHERE id = $1', [otherNotif.id]);
      expect(dbCheck.rows[0].is_read).toBe(false);
    });
  });
  // ==========================================
  // Zod Validations Edge Cases
  // ==========================================
  describe('Validation & Edge Cases', () => {
    it('should return 400 if pagination parameters are invalid (Zod)', async () => {
      // שליחת טקסט במקום מספר בפרמטר limit
      const response = await request(app).get('/api/v1/notifications?limit=notanumber');
      
      // השרת אמור לחסום את זה לפני שניגשים למסד הנתונים
      expect(response.statusCode).toBe(400);
    });

    it('should return 400 if notification ID is not a valid UUID (Zod)', async () => {
      // ניסיון סימון כנקרא עם ID שהוא סתם מחרוזת
      const response = await request(app).put('/api/v1/notifications/invalid-id-format/read');
      
      expect(response.statusCode).toBe(400);
    });
  });
});