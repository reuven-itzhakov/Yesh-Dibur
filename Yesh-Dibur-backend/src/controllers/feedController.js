const feedService = require('../services/feedService');
const { feedPaginationSchema } = require('../validations/feedValidation');

const feedController = {
  getDiscoveryFeed: async (req, res, next) => {
    try {
      const parsed = feedPaginationSchema.safeParse(req.query);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.errors });
      
      let { cursor, limit, radius_km } = parsed.data; 
      // אטימת קריסת שרת (DoS) במקרה של שליחת limit=0 שיגרום למערך לפנות לאינדקס שלילי
      limit = Math.max(Math.min(limit, 50), 1); 
      
      // אטימת קריסת Invalid Date (טיפול במחרוזת ריקה מצד הלקוח)
      if (cursor && cursor.trim() !== '') cursor = new Date(cursor);
      else cursor = null; 

      const feedData = await feedService.getDiscoveryFeed(req.user.uid, cursor, limit, radius_km);
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
      // אטימת קריסת שרת (DoS)
      limit = Math.max(Math.min(limit, 50), 1); 
      
      // אטימת קריסת Invalid Date
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