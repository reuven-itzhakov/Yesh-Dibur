const { pool } = require('../config/db');

const userService = {
  
  // 1. יצירת משתמש חדש
  createUser: async (uid, userData) => {
    const { name, email, phone, birth_date, location, interests, bio, instagram_url, tiktok_url, profile_image_url } = userData;
    
    // בניית השאילתה. אם יש מיקום, נמיר אותו לאובייקט גיאוגרפי של PostGIS
    const query = `
      INSERT INTO users (
        id, name, email, phone, birth_date, interests, bio, 
        instagram_url, tiktok_url, profile_image_url, location
      )
      VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
        ${location ? 'ST_SetSRID(ST_MakePoint($11, $12), 4326)' : 'NULL'}
      )
      RETURNING *;
    `;

    const values = [
      uid, name, email, phone, birth_date, interests, bio, 
      instagram_url, tiktok_url, profile_image_url
    ];

    if (location) {
      values.push(location.lng, location.lat); // PostGIS דורש אורך (lng) לפני רוחב (lat)
    }

    const { rows } = await pool.query(query, values);
    return rows[0];
  },

  // 2. שליפת הפרופיל האישי של המשתמש (כולל הכל)
  getUser: async (uid) => {
    const query = `
      SELECT *, ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat
      FROM users 
      WHERE id = $1 AND deleted_at IS NULL;
    `;
    const { rows } = await pool.query(query, [uid]);
    return rows[0];
  },

  // 3. עדכון פרופיל קיים (עדכון דינמי רק של השדות שנשלחו)
  updateUser: async (uid, data) => {
    const updates = [];
    const values = [];
    let paramIndex = 1;

    // בניית השאילתה באופן דינמי לפי מה שהלקוח שלח
    if (data.name) { updates.push(`name = $${paramIndex++}`); values.push(data.name); }
    if (data.bio !== undefined) { updates.push(`bio = $${paramIndex++}`); values.push(data.bio); }
    if (data.interests) { updates.push(`interests = $${paramIndex++}`); values.push(data.interests); }
    if (data.instagram_url !== undefined) { updates.push(`instagram_url = $${paramIndex++}`); values.push(data.instagram_url); }
    if (data.tiktok_url !== undefined) { updates.push(`tiktok_url = $${paramIndex++}`); values.push(data.tiktok_url); }
    if (data.profile_image_url) { updates.push(`profile_image_url = $${paramIndex++}`); values.push(data.profile_image_url); }
    
    if (data.location) {
      updates.push(`location = ST_SetSRID(ST_MakePoint($${paramIndex++}, $${paramIndex++}), 4326)`);
      values.push(data.location.lng, data.location.lat);
    }

    if (updates.length === 0) return null; // אין מה לעדכן

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(uid);

    const query = `
      UPDATE users 
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex} AND deleted_at IS NULL
      RETURNING *, ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat;
    `;

    const { rows } = await pool.query(query, values);
    return rows[0];
  },

  // 4. מחיקת חשבון (Soft Delete)
  deleteUser: async (uid) => {
    const query = `
      UPDATE users 
      SET deleted_at = CURRENT_TIMESTAMP 
      WHERE id = $1;
    `;
    await pool.query(query, [uid]);
  },

  // 5. שליפת פרופיל פומבי (ללא שדות רגישים כמו הגדרות, אימייל וטלפון)
  getPublicUser: async (id) => {
    const query = `
      SELECT id, name, birth_date, interests, bio, instagram_url, tiktok_url, profile_image_url, created_at
      FROM users 
      WHERE id = $1 AND deleted_at IS NULL;
    `;
    const { rows } = await pool.query(query, [id]);
    return rows[0];
  },

  // 6. שליפת מוני התראות ובאדג'ים (לסרגל הניווט)
  getUnreadCounts: async (uid) => {
    // נשלוף כמה התראות הלקוח עדיין לא קרא
    const query = `
      SELECT COUNT(*) as unread_notifications 
      FROM notifications 
      WHERE user_id = $1 AND is_read = FALSE;
    `;
    const { rows } = await pool.query(query, [uid]);
    
    return {
      notifications: parseInt(rows[0].unread_notifications, 10),
      messages: 0 // יש להשלים כשתבנה את מודול ה-Messages
    };
  },

  // 7. שליפת הקבוצות שהמשתמש חבר בהן
  getUserGroups: async (uid) => {
    const query = `
      SELECT g.id, g.name, g.description, g.cover_image_url, gm.joined_at
      FROM groups g
      JOIN group_members gm ON g.id = gm.group_id
      WHERE gm.user_id = $1;
    `;
    const { rows } = await pool.query(query, [uid]);
    return rows;
  }
};

module.exports = userService;