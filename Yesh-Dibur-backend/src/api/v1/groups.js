const express = require('express');
const authenticate = require('../../middlewares/auth');

const router = express.Router();

// Group routes
router.use(authenticate);

router.get('/', (req, res) => {
  // GET /api/v1/groups
});

router.post('/', (req, res) => {
  // POST /api/v1/groups
});

router.get('/:id', (req, res) => {
  // GET /api/v1/groups/:id
});

router.put('/:id', (req, res) => {
  // PUT /api/v1/groups/:id
});

router.delete('/:id', (req, res) => {
  // DELETE /api/v1/groups/:id
});

module.exports = router;
