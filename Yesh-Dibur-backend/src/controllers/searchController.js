const searchService = require('../services/searchService');
const { searchSchema } = require('../validations/searchValidation');

const searchController = {
  search: async (req, res, next) => {
    try {
      // הפעלת Zod על שורת הכתובת (req.query)
      const parsed = searchSchema.safeParse(req.query);
      if (!parsed.success) {
        return res.status(400).json({ error: parsed.error.errors });
      }

      const results = await searchService.search(req.user.uid, parsed.data);
      res.json(results);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = searchController;