const { pool } = require('../config/db');
const { getChannel } = require('../config/rabbitmq');

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
      const groupValues = [
        data.name, 
        data.description || null, 
        data.cover_image_url || null, 
        data.interests, 
        adminId
      ];
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

  getGroup: async (id, requesterId) => {
    const query = `
      SELECT g.*, 
             (SELECT COUNT(*) FROM group_members gm JOIN users u_mem ON gm.user_id = u_mem.id WHERE gm.group_id = g.id AND u_mem.deleted_at IS NULL) as members_count,
             EXISTS(SELECT 1 FROM group_members WHERE group_id = g.id AND user_id = $2) as is_member,
             u.name as admin_name, u.profile_image_url as admin_image
      FROM groups g
      JOIN users u ON g.admin_id = u.id
      WHERE g.id = $1
        AND u.deleted_at IS NULL
        -- חומת חסימות (הדדי)
        AND g.admin_id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        )
        -- חומת הפרדת הגילאים
        AND (
          (EXTRACT(YEAR FROM age((SELECT birth_date FROM users WHERE id = $2))) < 18 AND EXTRACT(YEAR FROM age(u.birth_date)) < 18)
          OR
          (EXTRACT(YEAR FROM age((SELECT birth_date FROM users WHERE id = $2))) >= 18 AND EXTRACT(YEAR FROM age(u.birth_date)) >= 18)
        );
    `;
    const { rows } = await pool.query(query, [id, requesterId]);
    return rows[0];
  },

  updateGroup: async (id, adminId, data) => {
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (data.name) { updates.push(`name = $${paramIndex++}`); values.push(data.name); }
    if (data.description !== undefined) { updates.push(`description = $${paramIndex++}`); values.push(data.description === '' ? null : data.description); }
    if (data.cover_image_url !== undefined) { updates.push(`cover_image_url = $${paramIndex++}`); values.push(data.cover_image_url === '' ? null : data.cover_image_url); }
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
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // 1. בדיקה שהמשתמש הוא אכן המנהל
      const check = await client.query('SELECT id FROM groups WHERE id = $1 AND admin_id = $2', [id, adminId]);
      if (check.rows.length === 0) {
        await client.query('ROLLBACK');
        return false;
      }

      // 2. מחיקת כל החברויות וההזמנות כדי למנוע שגיאת Foreign Key
      await client.query('DELETE FROM group_invitations WHERE group_id = $1', [id]);
      await client.query('DELETE FROM group_members WHERE group_id = $1', [id]);
      
      // 3. מחיקה רכה (Soft Delete) של כל הפוסטים בקבוצה כדי שייעלמו מהפיד
      await client.query('DELETE FROM thread_comments WHERE thread_id IN (SELECT id FROM threads WHERE group_id = $1)', [id]);
      await client.query('DELETE FROM thread_likes WHERE thread_id IN (SELECT id FROM threads WHERE group_id = $1)', [id]);
      await client.query('DELETE FROM threads WHERE group_id = $1', [id]);

      // 4. מחיקת הקבוצה עצמה בבטחה
      await client.query('DELETE FROM groups WHERE id = $1', [id]);

      await client.query('COMMIT');
      return true;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  joinGroup: async (groupId, userId) => {
    // במקום הכנסה עיוורת, מוודאים שאין חסימה מול מנהל הקבוצה ושיש התאמת גילאים
    const query = `
      INSERT INTO group_members (group_id, user_id) 
      SELECT g.id, $2
      FROM groups g
      JOIN users u_admin ON g.admin_id = u_admin.id
      JOIN users u_req ON u_req.id = $2
      WHERE g.id = $1
        AND u_admin.deleted_at IS NULL -- השורה שנוספה: מניעת הצטרפות לקבוצות יתומות
        AND g.admin_id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        )
        AND (
          (EXTRACT(YEAR FROM age(u_req.birth_date)) < 18 AND EXTRACT(YEAR FROM age(u_admin.birth_date)) < 18)
          OR
          (EXTRACT(YEAR FROM age(u_req.birth_date)) >= 18 AND EXTRACT(YEAR FROM age(u_admin.birth_date)) >= 18)
        )
      ON CONFLICT (group_id, user_id) DO NOTHING;
    `;
    const { rowCount } = await pool.query(query, [groupId, userId]);
    // אם לא הוכנסה שורה, זה אומר שהמשתמש כבר חבר או שנחסם על ידי חומות האבטחה
    if (rowCount === 0) throw new Error('NOT_ALLOWED_TO_JOIN');
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
    const checkInviter = await pool.query('SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2', [groupId, inviterId]);
    if (checkInviter.rows.length === 0) throw new Error('NOT_A_MEMBER');

    const checkInvitee = await pool.query('SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2', [groupId, inviteeId]);
    if (checkInvitee.rows.length > 0) throw new Error('ALREADY_A_MEMBER');

    // הוספת ההזמנה עם בדיקות מקיפות: חסימות וגילאים גם מול המזמין ו*גם מול מנהל הקבוצה* (למניעת כניסה בדלת האחורית)
    const query = `
      INSERT INTO group_invitations (inviter_id, invitee_id, group_id, status)
      SELECT $1, $2, $3, 'pending'
      FROM users u_inviter
      JOIN users u_invitee ON u_invitee.id = $2
      JOIN groups g ON g.id = $3
      JOIN users u_admin ON u_admin.id = g.admin_id
      WHERE u_inviter.id = $1
        -- חסימות מול המזמין
        AND $2 NOT IN (SELECT blocked_id FROM blocked_users WHERE blocker_id = $1 UNION SELECT blocker_id FROM blocked_users WHERE blocked_id = $1)
        -- חסימות מול מנהל הקבוצה (חובה!)
        AND $2 NOT IN (SELECT blocked_id FROM blocked_users WHERE blocker_id = g.admin_id UNION SELECT blocker_id FROM blocked_users WHERE blocked_id = g.admin_id)
        -- התאמת גילאים מול המזמין
        AND ((EXTRACT(YEAR FROM age(u_inviter.birth_date)) < 18 AND EXTRACT(YEAR FROM age(u_invitee.birth_date)) < 18) OR (EXTRACT(YEAR FROM age(u_inviter.birth_date)) >= 18 AND EXTRACT(YEAR FROM age(u_invitee.birth_date)) >= 18))
        -- התאמת גילאים מול מנהל הקבוצה (חובה!)
        AND ((EXTRACT(YEAR FROM age(u_admin.birth_date)) < 18 AND EXTRACT(YEAR FROM age(u_invitee.birth_date)) < 18) OR (EXTRACT(YEAR FROM age(u_admin.birth_date)) >= 18 AND EXTRACT(YEAR FROM age(u_invitee.birth_date)) >= 18))
        -- וידוא שאין כבר הזמנה פתוחה
        AND NOT EXISTS (SELECT 1 FROM group_invitations WHERE invitee_id = $2 AND group_id = $3 AND status = 'pending')
    `;
    const res = await pool.query(query, [inviterId, inviteeId, groupId]);
    if (res.rowCount === 0) throw new Error('INVITATION_BLOCKED');

    // שליחת התראת Push למוזמן כדי שידע שהזמינו אותו!
    const channel = getChannel();
    if (channel) {
      const pushPayload = { type: 'group_invite', groupId, senderId: inviterId, receiverId: inviteeId };
      channel.publish('', 'push', Buffer.from(JSON.stringify(pushPayload)));
    }
  }
};

module.exports = groupService;