const { pool } = require('../config/db');

const deviceService = {
  upsertDevice: async (userId, deviceId, fcmToken) => {
    const query = `
      INSERT INTO device_tokens (user_id, device_id, fcm_token)
      VALUES ($1, $2, $3)
      ON CONFLICT (user_id, device_id) 
      DO UPDATE SET fcm_token = EXCLUDED.fcm_token, created_at = CURRENT_TIMESTAMP
      RETURNING *;
    `;
    const { rows } = await pool.query(query, [userId, deviceId, fcmToken]);
    return rows[0];
  },

  deleteDevice: async (userId, deviceId) => {
    const query = 'DELETE FROM device_tokens WHERE user_id = $1 AND device_id = $2';
    await pool.query(query, [userId, deviceId]);
  }
};

module.exports = deviceService;