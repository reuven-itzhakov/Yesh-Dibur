const { pool } = require('../config/db');

const notificationService = {
  getNotifications: async (uid, limit = 20, offset = 0) => {
    // שולף את ההתראות תוך סינון שולחים שנמחקו או שנחסמו (כדי למנוע הטרדה)
    const query = `
      SELECT n.*, u.name as sender_name, u.profile_image_url as sender_image
      FROM notifications n
      LEFT JOIN users u ON n.sender_id = u.id
      WHERE n.user_id = $1
        AND (n.sender_id IS NULL OR u.deleted_at IS NULL)
        AND (n.sender_id IS NULL OR n.sender_id NOT IN (
          SELECT blocked_id FROM blocked_users WHERE blocker_id = $1
          UNION
          SELECT blocker_id FROM blocked_users WHERE blocked_id = $1
        ))
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