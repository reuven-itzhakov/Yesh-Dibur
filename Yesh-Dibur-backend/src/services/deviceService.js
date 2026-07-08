const { pool } = require('../config/db');

const deviceService = {
  upsertDevice: async (userId, deviceId, fcmToken) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // אטימת באג "התראות כפולות" ודליפות מידע:
      // 1. מחיקת המכשיר ממשתמשים קודמים (למשל אחים שמתחברים מאותו טלפון)
      // 2. מחיקת טוקן זהה ממכשירים ישנים של אותו משתמש (קורה בהתקנה מחדש של האפליקציה, מונע קבלת התראה כפולה!)
      await client.query(`
        DELETE FROM device_tokens 
        WHERE (device_id = $1 AND user_id != $3) 
           OR (fcm_token = $2 AND device_id != $1)
      `, [deviceId, fcmToken, userId]);
      
      // אטימת פרצת עומס (Push DoS): מחיקת מכשירים ישנים אם למשתמש יש יותר מ-4 מכשירים פעילים (נשמור רק את ה-5 החדשים)
      await client.query(`
        DELETE FROM device_tokens 
        WHERE user_id = $1 AND device_id NOT IN (
          SELECT device_id FROM device_tokens 
          WHERE user_id = $1 
          ORDER BY created_at DESC 
          LIMIT 4
        )
      `, [userId]);

      const query = `
        INSERT INTO device_tokens (user_id, device_id, fcm_token)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, device_id) 
        DO UPDATE SET fcm_token = EXCLUDED.fcm_token, created_at = CURRENT_TIMESTAMP
        RETURNING *;
      `;
      const { rows } = await client.query(query, [userId, deviceId, fcmToken]);
      
      await client.query('COMMIT');
      return rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  deleteDevice: async (userId, deviceId) => {
    const query = 'DELETE FROM device_tokens WHERE user_id = $1 AND device_id = $2';
    await pool.query(query, [userId, deviceId]);
  }
};

module.exports = deviceService;