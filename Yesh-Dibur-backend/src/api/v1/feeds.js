const express = require('express');
const authenticate = require('../../middlewares/auth');

const router = express.Router();

// Feed routes
router.use(authenticate);

router.get('/', (req, res) => {
  // GET /api/v1/feeds
});

module.exports = router;
