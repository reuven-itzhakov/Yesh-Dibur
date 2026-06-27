const express = require('express');
const authenticate = require('../../middlewares/auth');

const router = express.Router();

// Thread routes
router.use(authenticate);

router.get('/', (req, res) => {
  // GET /api/v1/threads
});

router.post('/', (req, res) => {
  // POST /api/v1/threads
});

router.get('/:id', (req, res) => {
  // GET /api/v1/threads/:id
});

router.put('/:id', (req, res) => {
  // PUT /api/v1/threads/:id
});

router.delete('/:id', (req, res) => {
  // DELETE /api/v1/threads/:id
});

module.exports = router;
