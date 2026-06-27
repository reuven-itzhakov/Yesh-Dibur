const express = require('express');
const authenticate = require('../../middlewares/auth');

const router = express.Router();

// User routes
router.use(authenticate);

router.get('/', (req, res) => {
  // GET /api/v1/users
});

router.get('/:id', (req, res) => {
  // GET /api/v1/users/:id
});

router.put('/:id', (req, res) => {
  // PUT /api/v1/users/:id
});

router.delete('/:id', (req, res) => {
  // DELETE /api/v1/users/:id
});

module.exports = router;
