const express = require('express');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const threadController = require('../../controllers/threadController');
const { createThreadSchema, createCommentSchema } = require('../../validations/threadValidation');

const router = express.Router();

router.use(authenticate);

// פעולות על פוסטים (Threads)
router.get('/:id', threadController.getThread);
router.post('/', validate(createThreadSchema), threadController.createThread);
router.delete('/:id', threadController.deleteThread);

// אינטראקציה עם פוסטים (לייקים)
router.post('/:id/like', threadController.toggleLike);

// פעולות על תגובות (Comments)
router.get('/:id/comments', threadController.getComments);
router.post('/:id/comments', validate(createCommentSchema), threadController.createComment);
router.delete('/:threadId/comments/:commentId', threadController.deleteComment);

module.exports = router;