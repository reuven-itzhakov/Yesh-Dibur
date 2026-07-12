const { pool } = require('../config/db');

const feedService = {
  
  // טאב 1: פיד הקבוצות שלי
  getMyGroupsFeed: async (uid, cursor, limit) => {
    let query = `
      SELECT 
        t.id, t.content, t.bg_type, t.bg_value, t.aspect_ratio, t.likes_count, t.comments_count, t.created_at,
        u.id as author_id, u.name as author_name, u.profile_image_url as author_image,
        g.id as group_id, g.name as group_name, g.image_url as group_image,
        EXISTS(SELECT 1 FROM thread_likes tl WHERE tl.thread_id = t.id AND tl.user_id = $1) as is_liked
      FROM threads t
      JOIN users u ON t.author_id = u.id
      JOIN groups g ON t.group_id = g.id
      JOIN group_members gm ON g.id = gm.group_id
      WHERE gm.user_id = $1 
        AND u.deleted_at IS NULL
        AND t.deleted_at IS NULL
        AND g.deleted_at IS NULL 
        AND (t.moderation_status = 'approved' OR (t.author_id = $1 AND t.moderation_status = 'pending')) 
        AND t.author_id NOT IN (SELECT blocked_id FROM blocked_users WHERE blocker_id = $1 UNION SELECT blocker_id FROM blocked_users WHERE blocked_id = $1)
        AND g.admin_id NOT IN (SELECT blocked_id FROM blocked_users WHERE blocker_id = $1 UNION SELECT blocker_id FROM blocked_users WHERE blocked_id = $1)
    `;

    const values = [uid];
    let paramIndex = 2;

    if (cursor) {
      query += ` AND t.created_at < $${paramIndex}`;
      values.push(cursor);
      paramIndex++;
    }

    query += ` ORDER BY t.created_at DESC LIMIT $${paramIndex}`;
    values.push(limit);

    const { rows } = await pool.query(query, values);
    const nextCursor = rows.length === limit ? rows[rows.length - 1].created_at : null;

    return { data: rows, next_cursor: nextCursor };
  },

  // טאב 2: פיד גילוי והמלצות (תומך במשתמשים רשומים ואורחים כאחד באופן בטוח)
  getDiscoveryFeed: async (uid, cursor, limit, radiusKm) => {
    let hasLocation = false;
    let isGuest = !uid;
    let user = null;

    if (!isGuest) {
      const userQuery = 'SELECT location, interests, EXTRACT(YEAR FROM age(birth_date)) as age FROM users WHERE id = $1 AND deleted_at IS NULL';
      const userRes = await pool.query(userQuery, [uid]);
      if (userRes.rows.length === 0) throw new Error('User not found');
      user = userRes.rows[0];
      hasLocation = !!user.location;
    }

    let query = `
      SELECT 
        t.id, t.content, t.bg_type, t.bg_value, t.aspect_ratio, t.likes_count, t.comments_count, t.created_at,
        u.id as author_id, u.name as author_name, u.profile_image_url as author_image,
        g.id as group_id, g.name as group_name, g.image_url as group_image,
    `;
    
    const values = [];
    let paramIndex = 1;

    // בנייה ליניארית ובטוחה של הפרמטרים
    if (isGuest) {
      query += ` FALSE as is_liked `;
    } else {
      query += ` EXISTS(SELECT 1 FROM thread_likes tl WHERE tl.thread_id = t.id AND tl.user_id = $${paramIndex}) as is_liked `;
      values.push(uid);
      paramIndex++; 
    }

    if (hasLocation && !isGuest) {
      query += `, ROUND(ST_Distance(u.location::geography, $${paramIndex}::geography) / 1000) as distance_km `;
      values.push(user.location);
      paramIndex++; 
    } else {
      query += `, NULL as distance_km `;
    }

    query += `
      FROM threads t
      JOIN users u ON t.author_id = u.id
      JOIN groups g ON t.group_id = g.id
      WHERE t.deleted_at IS NULL
        AND u.deleted_at IS NULL
        AND g.deleted_at IS NULL
        AND t.moderation_status = 'approved'
        AND g.is_private = FALSE
    `;

    if (!isGuest) {
      const uidParam = 1; // uid תמיד נכנס ראשון למערך, לכן אנחנו יודעים בביטחון שהוא משתנה מס' 1
      
      query += ` AND NOT EXISTS (SELECT 1 FROM group_members WHERE group_id = g.id AND user_id = $${uidParam}) `;

      query += `
        AND (
          ($${paramIndex} < 18 AND EXTRACT(YEAR FROM age(u.birth_date)) < 18)
          OR
          ($${paramIndex} >= 18 AND EXTRACT(YEAR FROM age(u.birth_date)) >= 18)
        )
      `;
      values.push(user.age);
      paramIndex++;

      query += `
        AND t.author_id NOT IN (SELECT blocked_id FROM blocked_users WHERE blocker_id = $${uidParam} UNION SELECT blocked_id FROM blocked_users WHERE blocked_id = $${uidParam})
        AND g.admin_id NOT IN (SELECT blocked_id FROM blocked_users WHERE blocker_id = $${uidParam} UNION SELECT blocked_id FROM blocked_users WHERE blocked_id = $${uidParam})
      `;
    } else {
      // אטימת הגנת הקטינים לאורחים: מחייבים חשיפה לתוכן של בגירים בלבד!
      query += ` AND EXTRACT(YEAR FROM age(u.birth_date)) >= 18 `;
    }

    if (hasLocation && !isGuest) {
       query += ` AND ST_DWithin(u.location::geography, $${paramIndex}::geography, $${paramIndex + 1} * 1000) `;
       values.push(user.location, radiusKm);
       paramIndex += 2;
    }

    if (!isGuest && user.interests && user.interests.length > 0) {
      query += ` AND (g.interests IS NULL OR g.interests && $${paramIndex}) `;
      values.push(user.interests);
      paramIndex++;
    }

    if (cursor) {
      query += ` AND t.created_at < $${paramIndex} `;
      values.push(cursor);
      paramIndex++;
    }

    query += ` ORDER BY t.created_at DESC LIMIT $${paramIndex} `;
    values.push(limit);

    const { rows } = await pool.query(query, values);
    const nextCursor = rows.length === limit ? rows[rows.length - 1].created_at : null;

    const formattedFeed = rows.map(row => {
      let distanceText = 'מרחק לא ידוע';
      if (row.distance_km !== null) {
        distanceText = row.distance_km < 1 ? 'קרוב אליך' : `במרחק ${row.distance_km} ק"מ`;
      }
      delete row.distance_km; 
      
      return {
        ...row,
        location_label: distanceText
      };
    });

    return {
      data: formattedFeed,
      next_cursor: nextCursor
    };
  }
};

module.exports = feedService;