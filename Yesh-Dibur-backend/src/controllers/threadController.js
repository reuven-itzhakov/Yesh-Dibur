const threadService = require('../services/threadService');

const threadController = {
  getThreads: async (req, res, next) => {
    try {
      const threads = await threadService.getThreads(req.query);
      res.json(threads);
    } catch (error) {
      next(error);
    }
  },

  createThread: async (req, res, next) => {
    try {
      const thread = await threadService.createThread(req.body);
      res.status(201).json(thread);
    } catch (error) {
      next(error);
    }
  },

  getThread: async (req, res, next) => {
    try {
      const thread = await threadService.getThread(req.params.id);
      if (!thread) return res.status(404).json({ error: 'Thread not found' });
      res.json(thread);
    } catch (error) {
      next(error);
    }
  },

  updateThread: async (req, res, next) => {
    try {
      const thread = await threadService.updateThread(req.params.id, req.body);
      res.json(thread);
    } catch (error) {
      next(error);
    }
  },

  deleteThread: async (req, res, next) => {
    try {
      await threadService.deleteThread(req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = threadController;
