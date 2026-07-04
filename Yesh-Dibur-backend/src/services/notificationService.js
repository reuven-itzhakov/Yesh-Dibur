const { pool } = require('../config/db');

const notificationService = {
  getNotifications: async (uid, limit = 20, offset = 0) => {
    // שולף את ההתראות ומצרף אליהן את שם השולח ותמונתו לתצוגה יפה במסך הפעמון
    const query = `
      SELECT n.*, u.name as sender_name, u.profile_image_url as sender_image
      FROM notifications n
      LEFT JOIN users u ON n.sender_id = u.id
      WHERE n.user_id = $1
      ORDER BY n.created_at DESC
      LIMIT $2 OFFSET $3;
    `;
    const { rows } = await pool.query(query, [uid, limit, offset]);
    return rows;
  },

  markAsRead: async (uid, notificationId) => {
    const query = 'UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2';
    await pool.query(query, [notificationId, uid]);
  },

  markAllAsRead: async (uid) => {
    const query = 'UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE';
    await pool.query(query, [uid]);
  }
};

module.exports = notificationService;