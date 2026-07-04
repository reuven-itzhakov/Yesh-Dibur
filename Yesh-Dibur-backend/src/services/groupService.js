const { pool } = require('../config/db');

const groupService = {
  
  createGroup: async (adminId, data) => {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN'); // התחלת טרנזקציה

      // 1. אכיפת מגבלת 5 קבוצות למנהל
      const countQuery = 'SELECT COUNT(*) FROM groups WHERE admin_id = $1';
      const countRes = await client.query(countQuery, [adminId]);
      
      if (parseInt(countRes.rows[0].count, 10) >= 5) {
        throw new Error('GROUP_LIMIT_REACHED');
      }

      // 2. יצירת הקבוצה
      const insertGroup = `
        INSERT INTO groups (name, description, cover_image_url, interests, admin_id)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *;
      `;
      const groupValues = [data.name, data.description, data.cover_image_url, data.interests, adminId];
      const groupRes = await client.query(insertGroup, groupValues);
      const newGroup = groupRes.rows[0];

      // 3. הוספת המנהל כחבר קבוצה אוטומטית (כדי שיראה פוסטים בפיד)
      const joinGroup = 'INSERT INTO group_members (group_id, user_id) VALUES ($1, $2)';
      await client.query(joinGroup, [newGroup.id, adminId]);

      await client.query('COMMIT'); // שמירת השינויים
      return newGroup;
    } catch (error) {
      await client.query('ROLLBACK'); // ביטול טרנזקציה במקרה של שגיאה
      throw error;
    } finally {
      client.release();
    }
  },

  getGroup: async (id) => {
    // שליפת הקבוצה יחד עם כמות החברים בה (Subquery פשוט)
    const query = `
      SELECT g.*, 
             (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as members_count
      FROM groups g
      WHERE g.id = $1;
    `;
    const { rows } = await pool.query(query, [id]);
    return rows[0];
  },

  updateGroup: async (id, adminId, data) => {
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (data.name) { updates.push(`name = $${paramIndex++}`); values.push(data.name); }
    if (data.description !== undefined) { updates.push(`description = $${paramIndex++}`); values.push(data.description); }
    if (data.cover_image_url !== undefined) { updates.push(`cover_image_url = $${paramIndex++}`); values.push(data.cover_image_url); }
    if (data.interests) { updates.push(`interests = $${paramIndex++}`); values.push(data.interests); }

    if (updates.length === 0) return null;

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    
    // מזהה הקבוצה ומזהה המנהל מוודאים שרק המנהל יכול לערוך
    values.push(id, adminId); 

    const query = `
      UPDATE groups 
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex} AND admin_id = $${paramIndex + 1}
      RETURNING *;
    `;

    const { rows } = await pool.query(query, values);
    return rows[0];
  },

  deleteGroup: async (id, adminId) => {
    // מחיקה המוגבלת רק למנהל הקבוצה
    const query = 'DELETE FROM groups WHERE id = $1 AND admin_id = $2 RETURNING id';
    const { rows } = await pool.query(query, [id, adminId]);
    return rows.length > 0;
  },

  joinGroup: async (groupId, userId) => {
    // שימוש ב-ON CONFLICT כדי למנוע קריסה אם המשתמש לוחץ פעמיים בטעות
    const query = `
      INSERT INTO group_members (group_id, user_id) 
      VALUES ($1, $2)
      ON CONFLICT (group_id, user_id) DO NOTHING;
    `;
    await pool.query(query, [groupId, userId]);
  },

  leaveGroup: async (groupId, userId) => {
    // 1. נוודא שהמשתמש הוא לא מנהל הקבוצה
    const adminCheck = await pool.query('SELECT admin_id FROM groups WHERE id = $1', [groupId]);
    if (adminCheck.rows.length > 0 && adminCheck.rows[0].admin_id === userId) {
      throw new Error('ADMIN_CANNOT_LEAVE');
    }

    // 2. מחיקת החברות בקבוצה
    const query = 'DELETE FROM group_members WHERE group_id = $1 AND user_id = $2';
    await pool.query(query, [groupId, userId]);
  },

  inviteUser: async (inviterId, inviteeId, groupId) => {
    const query = `
      INSERT INTO group_invitations (inviter_id, invitee_id, group_id)
      VALUES ($1, $2, $3)
    `;
    await pool.query(query, [inviterId, inviteeId, groupId]);
    
    // כאן בעתיד אפשר להפעיל את הפונקציה ששולחת משימה לתור ה-Push Notifications ב-RabbitMQ
  }
};

module.exports = groupService;