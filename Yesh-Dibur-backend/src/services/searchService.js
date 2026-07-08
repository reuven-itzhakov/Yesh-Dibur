const { pool } = require('../config/db');

const searchService = {
  search: async (uid, params) => {
    const { q, type, page, limit, radius_km, lat, lng, min_age, max_age, interests } = params;
    const offset = (page - 1) * limit;

    // שליפת המשתמש המחפש לטובת הגנת גיל ומיקום
    const uRes = await pool.query('SELECT location, EXTRACT(YEAR FROM age(birth_date)) as age FROM users WHERE id = $1', [uid]);
    const userLoc = uRes.rows[0]?.location;
    const userAge = parseInt(uRes.rows[0]?.age, 10);
    const isMinor = userAge < 18 || isNaN(userAge);

    // 1. חסימה אבסולוטית של גילאים (API Age Hacking Protection)
    let safeMinAge = min_age || null;
    let safeMaxAge = max_age || null;

    if (isMinor) {
      // קטין לא יכול בשום מצב לחפש מישהו שגילו 18 ומעלה
      if (!safeMaxAge || safeMaxAge >= 18) safeMaxAge = 17;
    } else {
      // בגיר לא יכול בשום מצב לחפש מישהו שגילו מתחת ל-18
      if (!safeMinAge || safeMinAge < 18) safeMinAge = 18;
    }

    const results = {};
    // מניעת באג חיפוש ריק (אם נשלחים רק פסיקים, המערך יקרוס את החיפוש ל-0 תוצאות)
    const rawInterests = interests ? interests.split(',').map(i => i.trim()).filter(i => i !== '') : [];
    const interestsArray = rawInterests.length > 0 ? rawInterests : null;

    let tsQuery = null;
    if (q) {
      const safeQ = q.replace(/[^\w\sא-ת]/gi, '').trim();
      if (safeQ) tsQuery = safeQ.split(/\s+/).map(word => word + ':*').join(' & ');
    }

    const blockedSubquery = `
      SELECT blocked_id FROM blocked_users WHERE blocker_id = $1
      UNION
      SELECT blocker_id FROM blocked_users WHERE blocked_id = $1
    `;

    // --- חיפוש משתמשים ---
    if (type === 'users' || type === 'all') {
      let uSelect = `
        SELECT id, name, bio, profile_image_url, interests,
               EXTRACT(YEAR FROM age(birth_date)) as age
      `;
      let uFromWhere = `
        FROM users
        WHERE deleted_at IS NULL 
          AND id != $1
          AND id NOT IN (${blockedSubquery})
      `;
      
      let uValues = [uid];
      let uIdx = 2;
      let centerGeom = null;
      let orderClauses = [];

      // חישובי מיקום
      if (lat !== undefined && lng !== undefined) {
         centerGeom = `ST_SetSRID(ST_MakePoint($${uIdx}, $${uIdx+1}), 4326)`;
         uValues.push(lng, lat);
         uIdx += 2;
      } else if (userLoc) {
         centerGeom = `$${uIdx}::geography`;
         uValues.push(userLoc);
         uIdx++;
      }

      if (centerGeom) {
        uSelect += `, ROUND(ST_Distance(location::geography, ${centerGeom}::geography) / 1000) as distance_km`;
        orderClauses.push(`distance_km ASC NULLS LAST`); // דירוג 2: מי הכי קרוב
      } else {
        uSelect += `, NULL as distance_km`;
      }

      // חיפוש טקסטואלי + דירוג רלוונטיות (שימוש ב-COALESCE למניעת קריסת מסד הנתונים)
      if (tsQuery) {
        uSelect += `, ts_rank(to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(bio, '')), to_tsquery('simple', $${uIdx})) as rank`;
        uFromWhere += ` AND to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(bio, '')) @@ to_tsquery('simple', $${uIdx})`;
        uValues.push(tsQuery);
        orderClauses.unshift(`rank DESC`);
        uIdx++;
      }

      // סינון גיל (מאובטח)
      if (safeMinAge) {
        uFromWhere += ` AND EXTRACT(YEAR FROM age(birth_date)) >= $${uIdx}`;
        uValues.push(safeMinAge);
        uIdx++;
      }
      if (safeMaxAge) {
        uFromWhere += ` AND EXTRACT(YEAR FROM age(birth_date)) <= $${uIdx}`;
        uValues.push(safeMaxAge);
        uIdx++;
      }

      if (radius_km && centerGeom) {
        uFromWhere += ` AND ST_DWithin(location::geography, ${centerGeom}::geography, $${uIdx} * 1000)`;
        uValues.push(radius_km);
        uIdx++;
      }
      
      if (interestsArray) {
        uFromWhere += ` AND interests && $${uIdx}`;
        uValues.push(interestsArray);
        uIdx++;
      }

      orderClauses.push(`created_at DESC`);
      const uQuery = `${uSelect} ${uFromWhere} ORDER BY ${orderClauses.join(', ')} LIMIT $${uIdx} OFFSET $${uIdx+1}`;
      uValues.push(limit, offset);

      const searchUsersRes = await pool.query(uQuery, uValues);
      
      results.users = searchUsersRes.rows.map(row => {
        let distanceText = 'מרחק לא ידוע';
        if (row.distance_km !== null) {
          distanceText = row.distance_km < 1 ? 'קרוב אליך' : `במרחק ${row.distance_km} ק"מ`;
        }
        delete row.distance_km;
        delete row.rank; // אין צורך לחשוף את הציון לאפליקציה
        return { ...row, location_label: distanceText };
      });
    }

    // --- חיפוש קבוצות ---
    if (type === 'groups' || type === 'all') {
      let gSelect = `
        SELECT g.id, g.name, g.description, g.image_url as group_image, g.is_private, g.interests,
               (SELECT COUNT(*) FROM group_members gm JOIN users u_mem ON gm.user_id = u_mem.id WHERE gm.group_id = g.id AND u_mem.deleted_at IS NULL) as members_count,
               EXISTS(SELECT 1 FROM group_members WHERE group_id = g.id AND user_id = $1) as is_member
      `;
      let gFromWhere = `
        FROM groups g
        JOIN users u ON g.admin_id = u.id
        WHERE u.deleted_at IS NULL 
          AND g.deleted_at IS NULL -- אטימת פרצה: חסימת קבוצות רפאים מחוקות
          AND (g.is_private = FALSE OR EXISTS (SELECT 1 FROM group_members WHERE group_id = g.id AND user_id = $1)) -- אטימת פרצה: הסתרת קבוצות פרטיות בחיפוש!
          AND g.admin_id NOT IN (${blockedSubquery})
      `;
      
      const gValues = [uid];
      let gIdx = 2;
      let orderClauses = [];

      if (tsQuery) {
        gSelect += `, ts_rank(to_tsvector('simple', g.name || ' ' || COALESCE(g.description, '')), to_tsquery('simple', $${gIdx})) as rank`;
        gFromWhere += ` AND to_tsvector('simple', g.name || ' ' || COALESCE(g.description, '')) @@ to_tsquery('simple', $${gIdx})`;
        gValues.push(tsQuery);
        orderClauses.push(`rank DESC`);
        gIdx++;
      }
      
      // הגנת קטינים גם על הקבוצות (לפי גיל המנהל)
      if (safeMinAge) {
        gFromWhere += ` AND EXTRACT(YEAR FROM age(u.birth_date)) >= $${gIdx}`;
        gValues.push(safeMinAge);
        gIdx++;
      }
      if (safeMaxAge) {
        gFromWhere += ` AND EXTRACT(YEAR FROM age(u.birth_date)) <= $${gIdx}`;
        gValues.push(safeMaxAge);
        gIdx++;
      }

      if (interestsArray) {
        gFromWhere += ` AND g.interests && $${gIdx}`;
        gValues.push(interestsArray);
        gIdx++;
      }

      orderClauses.push(`g.created_at DESC`);
      const gQuery = `${gSelect} ${gFromWhere} ORDER BY ${orderClauses.join(', ')} LIMIT $${gIdx} OFFSET $${gIdx+1}`;
      gValues.push(limit, offset);

      const gRes = await pool.query(gQuery, gValues);
      
      results.groups = gRes.rows.map(row => {
        delete row.rank;
        return row;
      });
    }

    return {
      data: results,
      pagination: { 
        page, 
        limit,
        has_next_users: results.users ? results.users.length === limit : false,
        has_next_groups: results.groups ? results.groups.length === limit : false
      }
    };
  }
};

module.exports = searchService;