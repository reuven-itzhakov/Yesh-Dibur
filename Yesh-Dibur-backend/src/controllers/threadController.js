const threadService = require('../services/threadService');

const threadController = {
  getThread: async (req, res, next) => {
    try {
      const thread = await threadService.getThread(req.params.id);
      if (!thread) return res.status(404).json({ error: 'Thread not found' });
      res.json(thread);
    } catch (error) {
      next(error);
    }
  },

  getGroupThreads: async (req, res, next) => {
    try {
      // שליפת כל הפוסטים השייכים לקבוצה הספציפית (req.params.id)
      const threads = await threadService.getGroupThreads(req.params.id);
      res.json(threads);
    } catch (error) {
      next(error);
    }
  },

  createThread: async (req, res, next) => {
    try {
      const thread = await threadService.createThread(req.user.uid, req.body);
      res.status(201).json(thread);
    } catch (error) {
      if (error.message === 'GROUP_NOT_FOUND') {
        return res.status(404).json({ error: 'Group does not exist or you are not a member.' });
      }
      next(error);
    }
  },

  deleteThread: async (req, res, next) => {
    try {
      const isDeleted = await threadService.deleteThread(req.params.id, req.user.uid);
      if (!isDeleted) return res.status(403).json({ error: 'Not authorized to delete this thread' });
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  toggleLike: async (req, res, next) => {
    try {
      const result = await threadService.toggleLike(req.params.id, req.user.uid);
      res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  },

  getComments: async (req, res, next) => {
    try {
      // כאן ניתן להוסיף בעתיד חילוץ של cursor מ-req.query לעימוד (Pagination)
      const comments = await threadService.getComments(req.params.id);
      res.json(comments);
    } catch (error) {
      next(error);
    }
  },

  createComment: async (req, res, next) => {
    try {
      const comment = await threadService.createComment(req.params.id, req.user.uid, req.body);
      res.status(201).json(comment);
    } catch (error) {
      next(error);
    }
  },

  deleteComment: async (req, res, next) => {
    try {
      const isDeleted = await threadService.deleteComment(req.params.threadId, req.params.commentId, req.user.uid);
      if (!isDeleted) return res.status(403).json({ error: 'Not authorized to delete this comment' });
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
};

module.exports = threadController;