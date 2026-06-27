const searchController = {
  search: async (req, res, next) => {
    try {
      const { q, type, page, limit } = req.query;
      // TODO: Implement search logic
      res.json({ results: [], query: q, type, page, limit });
    } catch (error) {
      next(error);
    }
  },
};

module.exports = searchController;
