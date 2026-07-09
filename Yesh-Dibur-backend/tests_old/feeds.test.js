const request = require('supertest');
const app = require('../src/app');
const { pool } = require('../src/config/db');

// ניהול המשתמש המחובר באופן דינמי
const authMiddleware = require('../src/middlewares/auth');
jest.mock('../src/middlewares/auth', () => {
  return jest.fn((req, res, next) => {
    req.user = { uid: 'user_main' }; 
    next();
  });
});

describe('Feeds API Integration Tests', () => {
  const userMain = 'user_main';
  const userClose = 'user_close'; // משתמש קרוב גיאוגרפית
  const userFar = 'user_far'; // משתמש רחוק גיאוגרפית
  const userBlocked = 'user_blocked'; // משתמש חסום

  let groupSportsId, groupTechId;

  beforeAll(async () => {
    // 1. ניקוי טבלאות
    await pool.query('DELETE FROM blocked_users');
    await pool.query('DELETE FROM thread_likes');
    await pool.query('DELETE FROM threads');
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3, $4)', [userMain, userClose, userFar, userBlocked]);

    // 2. יצירת משתמשים עם מיקומים גיאוגרפיים (PostGIS)
    const insertUser = `
      INSERT INTO users (id, name, email, birth_date, interests, location) 
      VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326))
    `;
    
    // Main User: תל אביב (34.7818, 32.0853), אוהב ספורט וטכנולוגיה
    await pool.query(insertUser, [userMain, 'Main User', 'main@test.com', new Date(), ['sports', 'tech'], 34.7818, 32.0853]);
    
    // Close User: רמת גן (~3 ק"מ מת"א)
    await pool.query(insertUser, [userClose, 'Close User', 'close@test.com', new Date(), ['sports'], 34.8113, 32.0823]);
    
    // Far User: חיפה (~90 ק"מ מת"א)
    await pool.query(insertUser, [userFar, 'Far User', 'far@test.com', new Date(), ['tech'], 34.9896, 32.7940]);
    
    // Blocked User: תל אביב
    await pool.query(insertUser, [userBlocked, 'Blocked User', 'blocked@test.com', new Date(), ['sports'], 34.7818, 32.0853]);

    // 3. חסימת המשתמש המטריד
    await pool.query('INSERT INTO blocked_users (blocker_id, blocked_id) VALUES ($1, $2)', [userMain, userBlocked]);

    // 4. יצירת קבוצות
    const groupRes1 = await pool.query('INSERT INTO groups (name, admin_id, interests) VALUES ($1, $2, $3) RETURNING id', ['Sports Group', userMain, ['sports']]);
    groupSportsId = groupRes1.rows[0].id;

    const groupRes2 = await pool.query('INSERT INTO groups (name, admin_id, interests) VALUES ($1, $2, $3) RETURNING id', ['Tech Group', userFar, ['tech']]);
    groupTechId = groupRes2.rows[0].id;

    // 5. צירוף משתמשים לקבוצות
    // Main User ו-Close User ו-Blocked User חברים בקבוצת הספורט
    await pool.query('INSERT INTO group_members (group_id, user_id) VALUES ($1, $2), ($1, $3), ($1, $4)', [groupSportsId, userMain, userClose, userBlocked]);
    // Far User חבר רק בקבוצת הטכנולוגיה
    await pool.query('INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)', [groupTechId, userFar]);
  });

  beforeEach(async () => {
    await pool.query('DELETE FROM thread_likes');
    await pool.query('DELETE FROM threads');
    authMiddleware.mockImplementation((req, res, next) => { req.user = { uid: userMain }; next(); });
  });

  afterAll(async () => {
    await pool.query('DELETE FROM blocked_users');
    await pool.query('DELETE FROM thread_likes');
    await pool.query('DELETE FROM threads');
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3, $4)', [userMain, userClose, userFar, userBlocked]);
    await pool.end();
  });

  // מזהי פוסטים שנוצרו בטסט
  const insertThread = async (groupId, authorId, content, status = 'approved') => {
    const res = await pool.query(`
      INSERT INTO threads (group_id, author_id, content, bg_type, bg_value, moderation_status)
      VALUES ($1, $2, $3, 'color', '#000', $4) RETURNING id, created_at
    `, [groupId, authorId, content, status]);
    return res.rows[0];
  };

  // ==========================================
  // GET /api/v1/feeds/my-groups
  // ==========================================
  describe('GET /api/v1/feeds/my-groups', () => {
    it('should return approved threads only from groups the user joined', async () => {
      // פוסט תקין מקבוצת ספורט (שהמשתמש חבר בה)
      await insertThread(groupSportsId, userClose, 'Sports Post 1');
      // פוסט מקבוצת טכנולוגיה (שהמשתמש לא חבר בה!)
      await insertThread(groupTechId, userFar, 'Tech Post 1');
      // פוסט שממתין לאישור (לא אמור להופיע)
      await insertThread(groupSportsId, userClose, 'Pending Post', 'pending');

      const response = await request(app).get('/api/v1/feeds/my-groups');
      
      expect(response.statusCode).toBe(200);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].content).toBe('Sports Post 1');
      expect(response.body.data[0].is_liked).toBe(false);
    });

    it('should completely hide threads from blocked users', async () => {
      await insertThread(groupSportsId, userClose, 'Good Post');
      await insertThread(groupSportsId, userBlocked, 'Blocked Post'); // פוסט ממשתמש חסום באותה קבוצה

      const response = await request(app).get('/api/v1/feeds/my-groups');
      
      expect(response.statusCode).toBe(200);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].content).toBe('Good Post'); // מוודאים שהפוסט החסום סונן
    });

    it('should indicate if the user liked a thread', async () => {
      const thread = await insertThread(groupSportsId, userClose, 'Likeable Post');
      await pool.query('INSERT INTO thread_likes (thread_id, user_id) VALUES ($1, $2)', [thread.id, userMain]);

      const response = await request(app).get('/api/v1/feeds/my-groups');
      expect(response.body.data[0].is_liked).toBe(true);
    });

    it('should paginate correctly using cursor and limit', async () => {
      // יצירת 3 פוסטים בהפרשי זמן
      for (let i = 1; i <= 3; i++) {
        await insertThread(groupSportsId, userClose, `Post ${i}`);
        await new Promise(r => setTimeout(r, 200)); // מרווח זמן קטן
      }

      // קריאה ראשונה: נבקש רק 2 פוסטים
      const res1 = await request(app).get('/api/v1/feeds/my-groups?limit=2');
      expect(res1.body.data.length).toBe(2);
      expect(res1.body.data[0].content).toBe('Post 3'); // החדש ביותר
      expect(res1.body.data[1].content).toBe('Post 2');
      expect(res1.body.next_cursor).not.toBeNull(); // יש עוד פוסטים

      // קריאה שנייה: נשתמש בסמן (Cursor) כדי להביא את העמוד הבא
      const res2 = await request(app).get(`/api/v1/feeds/my-groups?limit=2&cursor=${encodeURIComponent(res1.body.next_cursor)}`);
      expect(res2.body.data.length).toBe(1);
      expect(res2.body.data[0].content).toBe('Post 1'); // הפוסט הישן ביותר
      expect(res2.body.next_cursor).toBeNull(); // אין יותר פוסטים
    });
  });

  // ==========================================
  // GET /api/v1/feeds/discovery
  // ==========================================
  describe('GET /api/v1/feeds/discovery', () => {
    it('should fetch threads based on interests and default 10km radius', async () => {
      // פוסט קרוב (רמת גן - 3 ק"מ) - יכנס לפיד
      await insertThread(groupSportsId, userClose, 'Close Sports Post');
      // פוסט רחוק (חיפה - 90 ק"מ) - לא יכנס לפיד כי ברירת המחדל היא 10 ק"מ
      await insertThread(groupTechId, userFar, 'Far Tech Post');

      const response = await request(app).get('/api/v1/feeds/discovery');
      
      expect(response.statusCode).toBe(200);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].content).toBe('Close Sports Post');
      expect(response.body.data[0].location_label).toBe('במרחק 3 ק"מ'); // מוודא חישוב מרחק מדויק
    });

    it('should fetch farther threads if radius_km is increased', async () => {
      await insertThread(groupSportsId, userClose, 'Close Sports Post');
      await insertThread(groupTechId, userFar, 'Far Tech Post');

      // הלקוח מבקש במפורש רדיוס של 100 ק"מ
      const response = await request(app).get('/api/v1/feeds/discovery?radius_km=100');
      
      expect(response.statusCode).toBe(200);
      expect(response.body.data.length).toBe(2); // עכשיו שני הפוסטים בפנים
      
      const farPost = response.body.data.find(p => p.content === 'Far Tech Post');
      expect(farPost).toBeDefined();
      expect(farPost.location_label).toContain('ק"מ'); // יוודא שזה מצא את המרחק
    });

    it('should hide threads from blocked users in discovery as well', async () => {
      await insertThread(groupSportsId, userBlocked, 'Blocked User Post');
      
      const response = await request(app).get('/api/v1/feeds/discovery');
      expect(response.body.data.length).toBe(0); // הפיד ריק כי הפוסט סונן
    });

    it('should return 400 validation error if limit is invalid', async () => {
      const response = await request(app).get('/api/v1/feeds/discovery?limit=notanumber');
      expect(response.statusCode).toBe(400); // Zod Schema זורק שגיאה
    });

    it('should handle users with no location gracefully without crashing', async () => {
      // 1. ניצור משתמש ללא מיקום כלל
      const userNoLocId = 'user_no_loc';
      await pool.query(`
        INSERT INTO users (id, name, email, birth_date, interests) 
        VALUES ($1, $2, $3, $4, $5)
      `, [userNoLocId, 'No Location User', 'noloc@test.com', new Date(), ['tech']]);

      // 2. נכניס פוסט בנושא tech
      await insertThread(groupTechId, userFar, 'Tech post for no-loc user');

      // 3. נשנה את המשתמש המחובר למשתמש ללא המיקום
      authMiddleware.mockImplementationOnce((req, res, next) => {
        req.user = { uid: userNoLocId }; 
        next();
      });

      // 4. נבצע את הבקשה
      const response = await request(app).get('/api/v1/feeds/discovery');
      
      expect(response.statusCode).toBe(200);
      expect(response.body.data.length).toBeGreaterThan(0);
      
      // נוודא שהמערכת מחזירה תווית הגיונית כשאין מרחק
      expect(response.body.data[0].location_label).toBe('מרחק לא ידוע');

      // ניקוי המשתמש בסיום
      await pool.query('DELETE FROM users WHERE id = $1', [userNoLocId]);
    });

    it('should strictly exclude pending or rejected threads', async () => {
      await insertThread(groupSportsId, userClose, 'Approved Post', 'approved');
      await insertThread(groupSportsId, userClose, 'Pending Post', 'pending');
      await insertThread(groupSportsId, userClose, 'Rejected Bad Post', 'rejected');

      const response = await request(app).get('/api/v1/feeds/discovery');
      
      expect(response.statusCode).toBe(200);
      
      // אנחנו מוודאים שרק הפוסט המאושר עבר את המסנן
      const statuses = response.body.data.map(post => post.content);
      expect(statuses).toContain('Approved Post');
      expect(statuses).not.toContain('Pending Post');
      expect(statuses).not.toContain('Rejected Bad Post');
    });

    it('should exclude soft-deleted threads or threads from deleted users', async () => {
      // 1. פוסט שנמחק
      const deletedThread = await insertThread(groupSportsId, userClose, 'Deleted Thread');
      await pool.query('UPDATE threads SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1', [deletedThread.id]);

      // 2. פוסט תקין אך מאת משתמש שנמחק
      const deletedUser = 'user_to_delete';
      await pool.query(`
        INSERT INTO users (id, name, email, birth_date, interests, location) 
        VALUES ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint(34.78, 32.08), 4326))
      `, [deletedUser, 'Deleted', 'del@test.com', new Date(), ['sports']]);
      
      await insertThread(groupSportsId, deletedUser, 'Thread from deleted user');
      
      // מחיקה רכה של המשתמש
      await pool.query('UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1', [deletedUser]);

      const response = await request(app).get('/api/v1/feeds/discovery');
      
      expect(response.statusCode).toBe(200);
      const contents = response.body.data.map(post => post.content);
      
      expect(contents).not.toContain('Deleted Thread');
      expect(contents).not.toContain('Thread from deleted user');

      await pool.query('DELETE FROM users WHERE id = $1', [deletedUser]);
    });
  });
});