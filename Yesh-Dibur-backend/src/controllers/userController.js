const userService = require('../services/userService');

const userController = {
  // יצירת משתמש חדש במערכת
  registerUser: async (req, res, next) => {
    try {
      // כאן נעביר גם את נתוני המשתמש וגם את ה-UID שחולץ מהלקוח אם נרצה
      const newUser = await userService.createUser(req.user.uid, req.body);
      res.status(201).json(newUser);
    } catch (error) {
      next(error);
    }
  },

  // שליפת הפרופיל האישי של המשתמש המחובר
  getOwnProfile: async (req, res, next) => {
    try {
      const user = await userService.getUser(req.user.uid); // שימוש בטוקן המאומת
      if (!user) return res.status(404).json({ error: 'User profile not found' });
      res.json(user);
    } catch (error) {
      next(error);
    }
  },

  // עדכון הפרופיל האישי
  updateProfile: async (req, res, next) => {
    try {
      const updatedUser = await userService.updateUser(req.user.uid, req.body);
      res.json(updatedUser);
    } catch (error) {
      next(error);
    }
  },

  // מחיקת חשבון עצמית (מחיקה רכה)
  deleteAccount: async (req, res, next) => {
    try {
      await userService.deleteUser(req.user.uid);
      res.status(204).send(); // הצלחה ללא תוכן
    } catch (error) {
      next(error);
    }
  },

  // שליפת פרופיל פומבי של משתמש אחר
  getPublicProfile: async (req, res, next) => {
    try {
      const user = await userService.getPublicUser(req.params.id);
      if (!user) return res.status(404).json({ error: 'User not found' });
      res.json(user);
    } catch (error) {
      next(error);
    }
  },

  // שליפת מוני באדג'ים
  getBadges: async (req, res, next) => {
    try {
      const badges = await userService.getUnreadCounts(req.user.uid);
      res.json(badges);
    } catch (error) {
      next(error);
    }
  },

  // שליפת הקבוצות שלי
  getMyGroups: async (req, res, next) => {
    try {
      const groups = await userService.getUserGroups(req.user.uid);
      res.json(groups);
    } catch (error) {
      next(error);
    }
  }
};

module.exports = userController;