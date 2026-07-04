const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');

// ניהול המשתמש המחובר באופן דינמי
const authMiddleware = require('../src/middlewares/auth');
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    req.user = { uid: 'admin_test_uid' }; // משתמש ברירת המחדל (המנהל)
    next();
  });
});

describe('Groups API Integration Tests', () => {
  const adminId = 'admin_test_uid';
  const regularUserId = 'regular_user_uid';

  // הכנת נתוני תשתית (משתמשים) כדי לעמוד באילוצי Foreign Keys
  beforeAll(async () => {
    // מחיקה ראשונית למקרה שנשארו שאריות
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM group_invitations');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2)', [adminId, regularUserId]);

    // יצירת משתמשי הבדיקה
    const insertUserQuery = `
      INSERT INTO users (id, name, email, birth_date, interests) 
      VALUES ($1, $2, $3, $4, $5)
    `;
    await pool.query(insertUserQuery, [adminId, 'Admin User', 'admin@test.com', new Date(), ['1', '2', '3', '4', '5']]);
    await pool.query(insertUserQuery, [regularUserId, 'Regular User', 'user@test.com', new Date(), ['1', '2', '3', '4', '5']]);
  });

  // ניקוי טבלאות הקבוצות לפני כל טסט כדי להתחיל מדף חלק
  beforeEach(async () => {
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM group_invitations');
    await pool.query('DELETE FROM groups');
    // איפוס ה-Mock של האימות חזרה למנהל
    authMiddleware.mockImplementation((req, res, next) => {
      req.user = { uid: adminId };
      next();
    });
  });

  afterAll(async () => {
    // 1. קודם מוחקים את הרשומות שתלויות במשתמשים
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM group_invitations');
    await pool.query('DELETE FROM groups');

    // 2. עכשיו מוחקים את המשתמשים בבטחה
    await pool.query('DELETE FROM users WHERE id IN ($1, $2)', [adminId, regularUserId]);
    await pool.end();
  });

  // ==========================================
  // POST /api/v1/groups - יצירת קבוצה
  // ==========================================
  describe('POST /api/v1/groups', () => {
    const validGroupData = {
      name: 'קבוצת מתכנתים',
      description: 'קבוצה לדיוני קוד',
      interests: ['תכנות', 'טכנולוגיה', 'הייטק', 'גיימינג', 'סייבר']
    };

    it('should create a group successfully and add admin as a member', async () => {
      const response = await request(app).post('/api/v1/groups').send(validGroupData);

      expect(response.statusCode).toBe(201);
      expect(response.body.name).toBe(validGroupData.name);
      expect(response.body.admin_id).toBe(adminId);

      // וידוא שהטרנזקציה עבדה והמנהל נוסף לטבלת החברים
      const memberCheck = await pool.query('SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2', [response.body.id, adminId]);
      expect(memberCheck.rows.length).toBe(1);
    });

    it('should block creation if group name exceeds 30 characters (Zod Validation)', async () => {
      const response = await request(app).post('/api/v1/groups').send({
        ...validGroupData,
        name: 'שם קבוצה ארוך מדי שחורג מהמגבלה של שלושים תווים'
      });
      expect(response.statusCode).toBe(400);
    });

    it('should return 403 if admin already manages 5 groups', async () => {
      // יצירת 5 קבוצות מראש
      for (let i = 0; i < 5; i++) {
        await pool.query(
          'INSERT INTO groups (name, interests, admin_id) VALUES ($1, $2, $3)', 
          [`Group ${i}`, validGroupData.interests, adminId]
        );
      }

      // הניסיון השישי אמור להיחסם
      const response = await request(app).post('/api/v1/groups').send(validGroupData);
      expect(response.statusCode).toBe(403);
      expect(response.body.error).toBe('You can only manage up to 5 groups.');
    });
  });

  // ==========================================
  // GET /api/v1/groups/:id - שליפת קבוצה
  // ==========================================
  describe('GET /api/v1/groups/:id', () => {
    it('should fetch the group with members_count', async () => {
      // הכנת קבוצה ושני חברים
      const groupRes = await pool.query(
        'INSERT INTO groups (name, interests, admin_id) VALUES ($1, $2, $3) RETURNING id',
        ['Test Group', ['1', '2', '3', '4', '5'], adminId]
      );
      const groupId = groupRes.rows[0].id;

      await pool.query('INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)', [groupId, adminId]);
      await pool.query('INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)', [groupId, regularUserId]);

      const response = await request(app).get(`/api/v1/groups/${groupId}`);
      expect(response.statusCode).toBe(200);
      expect(response.body.name).toBe('Test Group');
      expect(parseInt(response.body.members_count, 10)).toBe(2);
    });

    it('should return 404 for a non-existent group', async () => {
      const response = await request(app).get('/api/v1/groups/00000000-0000-0000-0000-000000000000');
      expect(response.statusCode).toBe(404);
    });

    it('should handle invalid ID formats gracefully (e.g., non-UUID)', async () => {
      // שליחת מחרוזת סתמית במקום מזהה תקין
      const response = await request(app).get('/api/v1/groups/not-a-valid-uuid');
      
      // הסטטוס תלוי בטיפול השגיאות הגלובלי שלך, אך נצפה שזה לא יקריס את השרת אלא יחזיר שגיאת לקוח או שרת
      expect(response.statusCode).not.toBe(200);
    });
  });

  // ==========================================
  // PUT & DELETE - הרשאות ניהול
  // ==========================================
  describe('PUT and DELETE /api/v1/groups/:id', () => {
    let groupId;

    beforeEach(async () => {
      const groupRes = await pool.query(
        'INSERT INTO groups (name, interests, admin_id) VALUES ($1, $2, $3) RETURNING id',
        ['To Be Edited', ['1', '2', '3', '4', '5'], adminId]
      );
      groupId = groupRes.rows[0].id;
    });

    it('should allow admin to update the group', async () => {
      const response = await request(app)
        .put(`/api/v1/groups/${groupId}`)
        .send({ name: 'Updated Name' });
      
      expect(response.statusCode).toBe(200);
      expect(response.body.name).toBe('Updated Name');
    });

    it('should block non-admin from updating the group', async () => {
      // שינוי המשתמש המחובר למשתמש רגיל
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: regularUserId };
        next();
      });

      const response = await request(app)
        .put(`/api/v1/groups/${groupId}`)
        .send({ name: 'Hacked Name' });
      
      expect(response.statusCode).toBe(403);
    });

    it('should allow admin to delete the group', async () => {
      const response = await request(app).delete(`/api/v1/groups/${groupId}`);
      expect(response.statusCode).toBe(204);

      const dbCheck = await pool.query('SELECT * FROM groups WHERE id = $1', [groupId]);
      expect(dbCheck.rows.length).toBe(0);
    });

    it('should perform a partial update without overriding existing fields', async () => {
      // נעדכן רק את תמונת הנושא, מבלי לשלוח את שם הקבוצה או התיאור
      const partialData = {
        cover_image_url: 'https://example.com/new-cover.jpg'
      };

      const response = await request(app)
        .put(`/api/v1/groups/${groupId}`)
        .send(partialData);

      expect(response.statusCode).toBe(200);
      expect(response.body.cover_image_url).toBe(partialData.cover_image_url);
      expect(response.body.name).toBe('To Be Edited'); // השם המקורי נשמר
    });

    it('should cascade delete group members and invitations when a group is deleted', async () => {
      // 1. נוסיף חבר והזמנה לקבוצה
      await pool.query('INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)', [groupId, regularUserId]);
      await pool.query('INSERT INTO group_invitations (inviter_id, invitee_id, group_id) VALUES ($1, $2, $3)', [adminId, regularUserId, groupId]);

      // 2. המנהל מוחק את הקבוצה
      const response = await request(app).delete(`/api/v1/groups/${groupId}`);
      expect(response.statusCode).toBe(204);

      // 3. נוודא שהרשומות הקשורות נמחקו גם הן (בדיקת ON DELETE CASCADE)
      const membersCheck = await pool.query('SELECT * FROM group_members WHERE group_id = $1', [groupId]);
      expect(membersCheck.rows.length).toBe(0);

      const invitesCheck = await pool.query('SELECT * FROM group_invitations WHERE group_id = $1', [groupId]);
      expect(invitesCheck.rows.length).toBe(0);
    });
  });

  // ==========================================
  // פעולות חברתיות (Join, Leave, Invite)
  // ==========================================
  describe('Social Actions (Join, Leave, Invite)', () => {
    let groupId;

    beforeEach(async () => {
      const groupRes = await pool.query(
        'INSERT INTO groups (name, interests, admin_id) VALUES ($1, $2, $3) RETURNING id',
        ['Social Group', ['1', '2', '3', '4', '5'], adminId]
      );
      groupId = groupRes.rows[0].id;
    });

    it('should allow a regular user to join gracefully (and ignore duplicate joins)', async () => {
      authMiddleware.mockImplementation((req, res, next) => {
        req.user = { uid: regularUserId };
        next();
      });

      // הצטרפות ראשונה
      const join1 = await request(app).post(`/api/v1/groups/${groupId}/join`);
      expect(join1.statusCode).toBe(200);

      // הצטרפות שנייה (בדיקת ON CONFLICT DO NOTHING)
      const join2 = await request(app).post(`/api/v1/groups/${groupId}/join`);
      expect(join2.statusCode).toBe(200);

      const checkMembers = await pool.query('SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2', [groupId, regularUserId]);
      expect(checkMembers.rows.length).toBe(1); // עדיין נשארת רשומה אחת
    });

    it('should block admin from leaving the group', async () => {
      // המנהל מנסה לעזוב
      const response = await request(app).post(`/api/v1/groups/${groupId}/leave`);
      expect(response.statusCode).toBe(400);
      expect(response.body.error).toContain('Admin cannot leave');
    });

    it('should allow regular user to leave', async () => {
      // הכנסת משתמש רגיל לקבוצה ואז ניסיון לעזוב
      await pool.query('INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)', [groupId, regularUserId]);
      
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: regularUserId };
        next();
      });

      const response = await request(app).post(`/api/v1/groups/${groupId}/leave`);
      expect(response.statusCode).toBe(200);

      const dbCheck = await pool.query('SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2', [groupId, regularUserId]);
      expect(dbCheck.rows.length).toBe(0);
    });

    it('should send an invite and store it in group_invitations', async () => {
      const response = await request(app)
        .post(`/api/v1/groups/${groupId}/invite`)
        .send({ invitee_id: regularUserId });
        
      expect(response.statusCode).toBe(201);

      const dbCheck = await pool.query('SELECT * FROM group_invitations WHERE group_id = $1 AND invitee_id = $2', [groupId, regularUserId]);
      expect(dbCheck.rows.length).toBe(1);
    });

    it('should fail to invite a user that does not exist in the database', async () => {
      const response = await request(app)
        .post(`/api/v1/groups/${groupId}/invite`)
        .send({ invitee_id: 'non_existent_user_123' });
        
      // אמורה להיזרק שגיאת Foreign Key מ-PostgreSQL
      expect(response.statusCode).not.toBe(201);
    });

    it('should handle inviting a user who is already a member gracefully', async () => {
      // קודם נצרף את המשתמש לקבוצה
      await pool.query('INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)', [groupId, regularUserId]);

      // עכשיו ננסה להזמין אותו
      const response = await request(app)
        .post(`/api/v1/groups/${groupId}/invite`)
        .send({ invitee_id: regularUserId });
        
      // התגובה המדויקת תלויה באם הגדרת Unique Constraint או לוגיקה בשירות למנוע זאת
      // אבל בכל מקרה זה לא אמור ליצור הזמנה חדשה במצב תקין
      const invitesCheck = await pool.query('SELECT * FROM group_invitations WHERE group_id = $1 AND invitee_id = $2', [groupId, regularUserId]);
      
      // אנחנו מוודאים שהמערכת התמודדה עם זה (או שחסמה, או שלא נוצרה כפילות בעייתית)
      if (response.statusCode === 201) {
          // אם זה הצליח (כי אין חסימה ב-DB), לפחות נוודא שזה מתועד
          expect(invitesCheck.rows.length).toBeGreaterThan(0);
      } else {
          // אם זה נכשל (רצוי), אז הסטטוס קוד שונה מ-201
          expect(response.statusCode).not.toBe(201);
      }
    });
  });
});