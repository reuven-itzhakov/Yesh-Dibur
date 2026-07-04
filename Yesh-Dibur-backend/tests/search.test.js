const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');

// ניהול המשתמש המחובר באופן דינמי
const authMiddleware = require('../src/middlewares/auth');
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    req.user = { uid: 'minor_user_1' }; // נתחיל כמשתמש קטין
    next();
  });
});

// פונקציית עזר ליצירת תאריך לידה מדויק לפי גיל
const getBirthDate = (age) => {
  const d = new Date();
  d.setFullYear(d.getFullYear() - age);
  return d.toISOString();
};

describe('Search API Integration Tests', () => {
  const minorUser1 = 'minor_user_1'; // בן 16 (מחפש)
  const minorUser2 = 'minor_user_2'; // בן 17
  const adultUser1 = 'adult_user_1'; // בן 20
  const adultUser2 = 'adult_user_2'; // בת 22
  const blockedMinor = 'blocked_minor'; // בן 16 (חסום)

  let groupMinorId, groupAdultId;

  beforeAll(async () => {
    // 1. ניקוי עמוק של כל הטבלאות הקשורות
    await pool.query('DELETE FROM blocked_users');
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3, $4, $5)', [minorUser1, minorUser2, adultUser1, adultUser2, blockedMinor]);

    // 2. יצירת משתמשים עם גילאים, ביוגרפיות ומיקומים מגוונים
    const insertUser = `
      INSERT INTO users (id, name, bio, email, birth_date, interests, location) 
      VALUES ($1, $2, $3, $4, $5, $6, ST_SetSRID(ST_MakePoint($7, $8), 4326))
    `;
    
    // קטינים
    await pool.query(insertUser, [minorUser1, 'יוסי הקטין', 'אוהב לשחק כדורגל', 'y1@test.com', getBirthDate(16), ['sports'], 34.78, 32.08]);
    await pool.query(insertUser, [minorUser2, 'דניאל', 'מפתח תוכנה מתחיל', 'd1@test.com', getBirthDate(17), ['tech', 'gaming'], 34.80, 32.09]);
    await pool.query(insertUser, [blockedMinor, 'המטרידן', 'ביו סתמי', 'b1@test.com', getBirthDate(16), ['sports'], 34.78, 32.08]);
    
    // בגירים
    await pool.query(insertUser, [adultUser1, 'רונן הבגיר', 'סטודנט למדעי המחשב', 'r1@test.com', getBirthDate(20), ['tech'], 35.00, 31.50]);
    await pool.query(insertUser, [adultUser2, 'מיכל', 'אוהבת לטייל בעולם', 'm1@test.com', getBirthDate(22), ['travel'], 34.78, 32.08]);

    // 3. חסימה
    await pool.query('INSERT INTO blocked_users (blocker_id, blocked_id) VALUES ($1, $2)', [minorUser1, blockedMinor]);

    // 4. יצירת קבוצות (אחת מנוהלת ע"י קטין, אחת ע"י בגיר)
    const gRes1 = await pool.query('INSERT INTO groups (name, description, admin_id, interests) VALUES ($1, $2, $3, $4) RETURNING id', 
      ['קבוצת תכנות לנוער', 'לומדים פייתון ביחד', minorUser2, ['tech']]);
    groupMinorId = gRes1.rows[0].id;

    const gRes2 = await pool.query('INSERT INTO groups (name, description, admin_id, interests) VALUES ($1, $2, $3, $4) RETURNING id', 
      ['סטודנטים בטכניון', 'מדברים על מבחנים', adultUser1, ['tech']]);
    groupAdultId = gRes2.rows[0].id;
  });

  beforeEach(() => {
    // איפוס תמיד לקטין 1
    authMiddleware.mockImplementation((req, res, next) => { req.user = { uid: minorUser1 }; next(); });
  });

  afterAll(async () => {
    await pool.query('DELETE FROM blocked_users');
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3, $4, $5)', [minorUser1, minorUser2, adultUser1, adultUser2, blockedMinor]);
    await pool.end();
  });

  // ==========================================
  // Test Suite 1: הגנת קטינים / בגירים (Security)
  // ==========================================
  describe('Age Hacking Protection', () => {
    it('should strictly prevent a minor from finding adults, even if requested', async () => {
      // קטין מנסה לחפש אנשים עד גיל 30 בכוח דרך ה-URL
      const response = await request(app).get('/api/v1/search?type=users&max_age=30');
      
      expect(response.statusCode).toBe(200);
      const userNames = response.body.data.users.map(u => u.name);
      
      expect(userNames).toContain('דניאל'); // קטין אחר נמצא
      expect(userNames).not.toContain('רונן הבגיר'); // בגיר סונן החוצה
      expect(userNames).not.toContain('מיכל'); // בגירה סוננה החוצה
    });

    it('should strictly prevent an adult from finding minors, even if requested', async () => {
      // נשנה את ה-Mock למשתמש בגיר
      authMiddleware.mockImplementationOnce((req, res, next) => { req.user = { uid: adultUser1 }; next(); });

      // הבגיר מנסה לחפש משתמשים החל מגיל 16
      const response = await request(app).get('/api/v1/search?type=users&min_age=16');
      
      expect(response.statusCode).toBe(200);
      const userNames = response.body.data.users.map(u => u.name);
      
      expect(userNames).toContain('מיכל'); // בגירה אחרת נמצאת
      expect(userNames).not.toContain('יוסי הקטין'); // קטין סונן!
      expect(userNames).not.toContain('דניאל'); // קטין סונן!
    });

    it('should apply age protection to groups based on group admin age', async () => {
      // קטין (minorUser1) מחפש קבוצות
      const response = await request(app).get('/api/v1/search?type=groups');
      
      expect(response.statusCode).toBe(200);
      const groupNames = response.body.data.groups.map(g => g.name);
      
      expect(groupNames).toContain('קבוצת תכנות לנוער'); // מנוהל ע"י קטין
      expect(groupNames).not.toContain('סטודנטים בטכניון'); // מנוהל ע"י בגיר, נחסם!
    });
  });

  // ==========================================
  // Test Suite 2: Full-Text Search (FTS)
  // ==========================================
  describe('Full Text Search (q)', () => {
    it('should rank exact text matches higher', async () => {
      // דניאל מתכנת, לקבוצה קוראים "קבוצת תכנות לנוער".
      // נחפש את המילה "תוכנה" (נמצא בביו של דניאל).
      const response = await request(app).get(encodeURI('/api/v1/search?q=תוכנה'));
      
      expect(response.statusCode).toBe(200);
      
      // בדיקת משתמשים
      expect(response.body.data.users.length).toBeGreaterThan(0);
      expect(response.body.data.users[0].name).toBe('דניאל');
      expect(response.body.data.users[0].bio).toContain('תוכנה');
    });

    it('should handle special characters gracefully without crashing SQL', async () => {
      const response = await request(app).get(encodeURI('/api/v1/search?q=היי!!! *** מפתח;;'));
      expect(response.statusCode).toBe(200); // ה-Regex שמנקה תווים עבד ולא קרס
    });
  });

  // ==========================================
  // Test Suite 3: Blocked Users & Locations
  // ==========================================
  describe('Filters (Blocked, Interests, Location)', () => {
    it('should completely hide blocked users from search results', async () => {
      const response = await request(app).get('/api/v1/search?type=users');
      
      const userNames = response.body.data.users.map(u => u.name);
      expect(userNames).not.toContain('המטרידן'); // המשתמש שחסמנו לא קיים
    });

    it('should filter correctly by specific interests', async () => {
      const response = await request(app).get('/api/v1/search?interests=gaming');
      
      expect(response.statusCode).toBe(200);
      const userNames = response.body.data.users.map(u => u.name);
      
      expect(userNames).toContain('דניאל'); // יש לו gaming
      expect(userNames.length).toBe(1); // האחרים סוננו כי אין להם gaming (וסוננו גם בגירים)
    });

    it('should search using custom lat/lng coordinates and radius', async () => {
      // נחפש סביב הקואורדינטות של דניאל (34.80, 32.09) ברדיוס צר
      const response = await request(app).get('/api/v1/search?type=users&lat=32.09&lng=34.80&radius_km=5');
      
      expect(response.statusCode).toBe(200);
      expect(response.body.data.users[0].name).toBe('דניאל');
      expect(response.body.data.users[0].location_label).toBe('קרוב אליך'); // מרחק 0 (אותו מיקום ששלחנו)
    });
  });

  // ==========================================
  // Test Suite 4: Pagination & Types
  // ==========================================
  describe('Pagination & Types', () => {
    it('should fetch only groups when type=groups', async () => {
      const response = await request(app).get('/api/v1/search?type=groups');
      expect(response.body.data.users).toBeUndefined();
      expect(response.body.data.groups).toBeDefined();
    });

    it('should fetch both when type=all', async () => {
      const response = await request(app).get('/api/v1/search?type=all');
      expect(response.body.data.users).toBeDefined();
      expect(response.body.data.groups).toBeDefined();
    });

    it('should handle pagination limits correctly', async () => {
      // נגביל לתוצאה אחת בלבד
      const response = await request(app).get('/api/v1/search?limit=1');
      expect(response.body.data.users.length).toBeLessThanOrEqual(1);
      
      // נוודא שה-pagination מדווח שיש עוד עמודים
      expect(response.body.pagination.has_next_users).toBe(true);
    });

    it('should not leak sensitive user info in search results', async () => {
      const response = await request(app).get('/api/v1/search?type=users');
      const user = response.body.data.users[0];
      expect(user).not.toHaveProperty('email');
      expect(user).not.toHaveProperty('phone');
      expect(user).not.toHaveProperty('location');
    });
  });
});