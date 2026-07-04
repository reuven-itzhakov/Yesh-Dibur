const notificationService = require('../services/notificationService');

const notificationController = {
  getNotifications: async (req, res, next) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const offset = (page - 1) * limit;

      const notifications = await notificationService.getNotifications(req.user.uid, limit, offset);
      res.json(notifications);
    } catch (error) {
      next(error);
    }
  },

  markAsRead: async (req, res, next) => {
    try {
      await notificationService.markAsRead(req.user.uid, req.params.id);
      res.status(200).json({ message: 'Notification marked as read' });
    } catch (error) {
      next(error);
    }
  },

  markAllAsRead: async (req, res, next) => {
    try {
      await notificationService.markAllAsRead(req.user.uid);
      res.status(200).json({ message: 'All notifications marked as read' });
    } catch (error) {
      next(error);
    }
  }
};

module.exports = notificationController;