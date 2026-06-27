const feedController = {
  getFeed: async (req, res, next) => {
    try {
      const { page, limit } = req.query;
      // TODO: Implement feed logic
      res.json({ feed: [], page, limit });
    } catch (error) {
      next(error);
    }
  },
};

module.exports = feedController;
