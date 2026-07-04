const feedService = require('../services/feedService');
const { feedPaginationSchema } = require('../validations/feedValidation');

const feedController = {
  getDiscoveryFeed: async (req, res, next) => {
    try {
      const parsed = feedPaginationSchema.safeParse(req.query);
      if (!parsed.success) {
        return res.status(400).json({ error: parsed.error.errors });
      }
      
      let { cursor, limit, radius_km } = parsed.data; 
      
      // המרת המחרוזת לאובייקט Date כדי למנוע בעיות אזור זמן ודיוק מול PostgreSQL
      if (cursor) cursor = new Date(cursor);

      const feedData = await feedService.getDiscoveryFeed(req.user.uid, cursor, limit, radius_km);
      res.json(feedData);
    } catch (error) {
      next(error);
    }
  },

  getMyGroupsFeed: async (req, res, next) => {
    try {
      const parsed = feedPaginationSchema.safeParse(req.query);
      if (!parsed.success) {
        return res.status(400).json({ error: parsed.error.errors });
      }

      let { cursor, limit } = parsed.data; 
      
      // המרת המחרוזת לאובייקט Date כדי למנוע בעיות אזור זמן ודיוק מול PostgreSQL
      if (cursor) cursor = new Date(cursor);

      const feedData = await feedService.getMyGroupsFeed(req.user.uid, cursor, limit);
      res.json(feedData);
    } catch (error) {
      next(error);
    }
  }
};

module.exports = feedController;