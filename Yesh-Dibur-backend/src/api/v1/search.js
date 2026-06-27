const express = require('express');
const authenticate = require('../../middlewares/auth');

const router = express.Router();

// Search routes
router.use(authenticate);

router.get('/', (req, res) => {
  // GET /api/v1/search
});

module.exports = router;
