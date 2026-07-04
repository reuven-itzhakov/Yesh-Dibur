const feedService = require('../services/feedService');

const feedController = {
  getDiscoveryFeed: async (req, res, next) => {
    try {
      const { cursor, limit, radius_km } = req.query; 
      const feedData = await feedService.getDiscoveryFeed(req.user.uid, cursor, limit, radius_km);
      res.json(feedData);
    } catch (error) {
      next(error);
    }
  },

  getMyGroupsFeed: async (req, res, next) => {
    try {
      const { cursor, limit } = req.query; 
      const feedData = await feedService.getMyGroupsFeed(req.user.uid, cursor, limit);
      res.json(feedData);
    } catch (error) {
      next(error);
    }
  }
};

module.exports = feedController;