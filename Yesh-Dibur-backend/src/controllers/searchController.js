const searchService = require('../services/searchService');

const searchController = {
  search: async (req, res, next) => {
    try {
      // req.query כבר עבר המרה למספרים ואימות דרך Zod
      const results = await searchService.search(req.user.uid, req.query);
      res.json(results);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = searchController;