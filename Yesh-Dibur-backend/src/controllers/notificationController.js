const notificationService = require('../services/notificationService');
const { notificationPaginationSchema, notificationIdSchema } = require('../validations/notificationValidation');

const notificationController = {
  getNotifications: async (req, res, next) => {
    try {
      const { page, limit } = notificationPaginationSchema.parse(req.query);
      const offset = (page - 1) * limit;

      const notifications = await notificationService.getNotifications(req.user.uid, limit, offset);
      res.json(notifications);
    } catch (error) {
      next(error); 
    }
  },

  markAsRead: async (req, res, next) => {
    try {
      // הפעלת הוולידציה במפורש על פרמטרי הנתיב (req.params)
      const parsed = notificationIdSchema.safeParse({ id: req.params.id });
      if (!parsed.success) {
        return res.status(400).json({ error: parsed.error.errors });
      }

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