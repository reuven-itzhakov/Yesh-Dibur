const groupService = require('../services/groupService');

const groupController = {
  getGroups: async (req, res, next) => {
    try {
      const groups = await groupService.getGroups(req.query);
      res.json(groups);
    } catch (error) {
      next(error);
    }
  },

  createGroup: async (req, res, next) => {
    try {
      const group = await groupService.createGroup(req.body);
      res.status(201).json(group);
    } catch (error) {
      next(error);
    }
  },

  getGroup: async (req, res, next) => {
    try {
      const group = await groupService.getGroup(req.params.id);
      if (!group) return res.status(404).json({ error: 'Group not found' });
      res.json(group);
    } catch (error) {
      next(error);
    }
  },

  updateGroup: async (req, res, next) => {
    try {
      const group = await groupService.updateGroup(req.params.id, req.body);
      res.json(group);
    } catch (error) {
      next(error);
    }
  },

  deleteGroup: async (req, res, next) => {
    try {
      await groupService.deleteGroup(req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = groupController;
