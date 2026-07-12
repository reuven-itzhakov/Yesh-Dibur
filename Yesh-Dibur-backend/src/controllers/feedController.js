const feedService = require('../services/feedService');
const { feedPaginationSchema } = require('../validations/feedValidation');

const feedController = {
  getDiscoveryFeed: async (req, res, next) => {
    try {
      const parsed = feedPaginationSchema.safeParse(req.query);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.errors });
      
      let { cursor, limit, radius_km } = parsed.data; 
      limit = Math.max(Math.min(limit, 50), 1); 
      
      if (cursor && cursor.trim() !== '') cursor = new Date(cursor);
      else cursor = null; 

      // אטימת קריסה: חילוץ בטוח של המזהה (הגנה מפני אורחים)
      const uid = req.user ? req.user.uid : null;

      const feedData = await feedService.getDiscoveryFeed(uid, cursor, limit, radius_km);
      res.json(feedData);
    } catch (error) {
      next(error);
    }
  },

  getMyGroupsFeed: async (req, res, next) => {
    try {
      const parsed = feedPaginationSchema.safeParse(req.query);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.errors });

      let { cursor, limit } = parsed.data; 
      limit = Math.max(Math.min(limit, 50), 1); 
      
      if (cursor && cursor.trim() !== '') cursor = new Date(cursor);
      else cursor = null;

      const feedData = await feedService.getMyGroupsFeed(req.user.uid, cursor, limit);
      res.json(feedData);
    } catch (error) {
      next(error);
    }
  }
};

module.exports = feedController;