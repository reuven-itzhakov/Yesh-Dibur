const express = require('express');
const authenticate = require('../../middlewares/auth');

const router = express.Router();

// Chat routes
router.use(authenticate);

router.get('/', (req, res) => {
  // GET /api/v1/chats
});

router.post('/', (req, res) => {
  // POST /api/v1/chats
});

router.get('/:id', (req, res) => {
  // GET /api/v1/chats/:id
});

router.delete('/:id', (req, res) => {
  // DELETE /api/v1/chats/:id
});

module.exports = router;
