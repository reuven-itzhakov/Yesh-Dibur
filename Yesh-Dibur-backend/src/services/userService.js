const { pool } = require('../config/db');

const userService = {
  
  createUser: async (uid, userData) => {
    const { name, email, phone, birth_date, location, interests, bio, instagram_url, tiktok_url, profile_image_url } = userData;
    
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
      values.push(location.lng, location.lat);
    }

    const { rows } = await pool.query(query, values);
    return rows[0];
  },

  getUser: async (uid) => {
    const query = `
      SELECT *, ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat
      FROM users 
      WHERE id = $1 AND deleted_at IS NULL;
    `;
    const { rows } = await pool.query(query, [uid]);
    return rows[0];
  },

  updateUser: async (uid, data) => {
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (data.name) { updates.push(`name = $${paramIndex++}`); values.push(data.name); }
    if (data.bio !== undefined) { updates.push(`bio = $${paramIndex++}`); values.push(data.bio); }
    if (data.interests) { updates.push(`interests = $${paramIndex++}`); values.push(data.interests); }
    if (data.instagram_url !== undefined) { updates.push(`instagram_url = $${paramIndex++}`); values.push(data.instagram_url); }
    if (data.tiktok_url !== undefined) { updates.push(`tiktok_url = $${paramIndex++}`); values.push(data.tiktok_url); }
    if (data.profile_image_url) { updates.push(`profile_image_url = $${paramIndex++}`); values.push(data.profile_image_url); }
    if (data.settings) { updates.push(`settings = $${paramIndex++}`); values.push(data.settings); }
    
    if (data.location) {
      updates.push(`location = ST_SetSRID(ST_MakePoint($${paramIndex++}, $${paramIndex++}), 4326)`);
      values.push(data.location.lng, data.location.lat);
    }

    if (updates.length === 0) return null;

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

  updateLocation: async (uid, location) => {
    const query = `
      UPDATE users 
      SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326), updated_at = CURRENT_TIMESTAMP
      WHERE id = $3 AND deleted_at IS NULL;
    `;
    await pool.query(query, [location.lng, location.lat, uid]);
  },

  blockUser: async (blockerId, blockedId) => {
    if (blockerId === blockedId) throw new Error('CANNOT_BLOCK_SELF');
    
    // ON CONFLICT מונע קריסה אם המשתמש כבר חסום
    const query = `
      INSERT INTO blocked_users (blocker_id, blocked_id) 
      VALUES ($1, $2)
      ON CONFLICT DO NOTHING;
    `;
    await pool.query(query, [blockerId, blockedId]);
  },

  unblockUser: async (blockerId, blockedId) => {
    const query = `DELETE FROM blocked_users WHERE blocker_id = $1 AND blocked_id = $2`;
    await pool.query(query, [blockerId, blockedId]);
  },

  deleteUser: async (uid) => {
    const query = `
      UPDATE users 
      SET deleted_at = CURRENT_TIMESTAMP 
      WHERE id = $1;
    `;
    await pool.query(query, [uid]);
  },

getPublicUser: async (id, requesterId) => {
    const query = `
      SELECT 
        u.id, u.name, 
        EXTRACT(YEAR FROM age(u.birth_date)) as age, 
        u.interests, u.bio, u.instagram_url, u.tiktok_url, u.profile_image_url, u.created_at,
        ROUND(ST_Distance(u.location::geography, (SELECT location FROM users WHERE id = $2)::geography) / 1000) as distance_km
      FROM users u
      WHERE u.id = $1 
        AND u.deleted_at IS NULL
        AND u.id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $2
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $2
        );
    `;
    const { rows } = await pool.query(query, [id, requesterId]);
    
    if (rows.length === 0) return null;
    
    const user = rows[0];
    
    // אכיפת טשטוש המיקום והמרתו לטקסט ידידותי למשתמש
    let distanceText = 'מרחק לא ידוע';
    if (user.distance_km !== null) {
      distanceText = user.distance_km < 1 ? 'קרוב אליך' : `במרחק ${user.distance_km} ק"מ`;
    }
    delete user.distance_km; // מסירים את המספר המדויק כדי שלא יזלוג בטעות לאפליקציה
    user.location_label = distanceText;
    
    return user;
  },

  getUnreadCounts: async (uid) => {
    const query = `
      SELECT 
        (SELECT COUNT(*) FROM notifications n 
         LEFT JOIN users u ON n.sender_id = u.id 
         WHERE n.user_id = $1 
           AND n.is_read = FALSE
           AND (n.sender_id IS NULL OR u.deleted_at IS NULL)
           AND (n.sender_id IS NULL OR n.sender_id NOT IN (
             SELECT blocked_id FROM blocked_users WHERE blocker_id = $1
             UNION
             SELECT blocker_id FROM blocked_users WHERE blocked_id = $1
           ))
        ) as unread_notifications,
        (SELECT COUNT(*) FROM messages m
         JOIN users u ON m.sender_id = u.id
         WHERE m.receiver_id = $1 
           AND m.status IN ('approved', 'pending_approval')
           AND u.deleted_at IS NULL
           AND m.sender_id NOT IN (
             SELECT blocked_id FROM blocked_users WHERE blocker_id = $1
             UNION
             SELECT blocker_id FROM blocked_users WHERE blocked_id = $1
           )
        ) as unread_messages
    `;
    const { rows } = await pool.query(query, [uid]);
    
    return {
      notifications: parseInt(rows[0].unread_notifications || 0, 10),
      messages: parseInt(rows[0].unread_messages || 0, 10)
    };
  },

  getUserGroups: async (uid) => {
    const query = `
      SELECT g.id, g.name, g.description, g.cover_image_url, gm.joined_at
      FROM groups g
      JOIN group_members gm ON g.id = gm.group_id
      WHERE gm.user_id = $1;
    `;
    const { rows } = await pool.query(query, [uid]);
    return rows;
  },

  // מענה להזמנה לקבוצה
  respondToInvitation: async (uid, invitationId, status) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // עדכון סטטוס ההזמנה (רק אם היא ממתינה ושייכת למשתמש הזה)
      const query = `
        UPDATE group_invitations 
        SET status = $1, updated_at = CURRENT_TIMESTAMP
        WHERE id = $2 AND invitee_id = $3 AND status = 'pending'
        RETURNING group_id;
      `;
      const res = await client.query(query, [status, invitationId, uid]);
      
      if (res.rows.length === 0) {
        throw new Error('INVITATION_NOT_FOUND');
      }

      // אם המשתמש אישר, נוסיף אותו מיד לטבלת חברי הקבוצה
      // אם המשתמש אישר, נוסיף אותו מיד לטבלת חברי הקבוצה - רק אם הוא עומד בחוקי הגיל והחסימות מול המנהל!
      if (status === 'approved') {
        const groupId = res.rows[0].group_id;
        const joinQuery = `
          INSERT INTO group_members (group_id, user_id) 
          SELECT g.id, $2
          FROM groups g
          JOIN users u_admin ON g.admin_id = u_admin.id
          JOIN users u_req ON u_req.id = $2
          WHERE g.id = $1
            AND u_admin.deleted_at IS NULL
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
        const joinRes = await client.query(joinQuery, [groupId, uid]);
        if (joinRes.rowCount === 0) {
          throw new Error('NOT_ALLOWED_TO_JOIN_GROUP');
        }
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
};

module.exports = userService;