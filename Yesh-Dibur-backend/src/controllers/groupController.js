const groupService = require('../services/groupService');

const groupController = {
  createGroup: async (req, res, next) => {
    try {
      // מעבירים ל-Service גם את מזהה המשתמש שיהפוך למנהל
      const group = await groupService.createGroup(req.user.uid, req.body);
      res.status(201).json(group);
    } catch (error) {
      if (error.message === 'GROUP_LIMIT_REACHED') {
        return res.status(403).json({ error: 'You can only manage up to 5 groups.' });
      }
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
      const group = await groupService.updateGroup(req.params.id, req.user.uid, req.body);
      if (!group) return res.status(403).json({ error: 'Not authorized or group not found' });
      res.json(group);
    } catch (error) {
      next(error);
    }
  },

  deleteGroup: async (req, res, next) => {
    try {
      const deleted = await groupService.deleteGroup(req.params.id, req.user.uid);
      if (!deleted) return res.status(403).json({ error: 'Not authorized to delete this group' });
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  joinGroup: async (req, res, next) => {
    try {
      await groupService.joinGroup(req.params.id, req.user.uid);
      res.status(200).json({ message: 'Successfully joined the group' });
    } catch (error) {
      next(error);
    }
  },

  leaveGroup: async (req, res, next) => {
    try {
      await groupService.leaveGroup(req.params.id, req.user.uid);
      res.status(200).json({ message: 'Successfully left the group' });
    } catch (error) {
      if (error.message === 'ADMIN_CANNOT_LEAVE') {
        return res.status(400).json({ error: 'Admin cannot leave the group. You must delete it or transfer ownership.' });
      }
      next(error);
    }
  },

  inviteUser: async (req, res, next) => {
    try {
      await groupService.inviteUser(req.user.uid, req.body.invitee_id, req.params.id);
      res.status(201).json({ message: 'Invitation sent successfully' });
    } catch (error) {
      next(error);
    }
  }
};

module.exports = groupController;