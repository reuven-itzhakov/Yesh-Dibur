const userService = require('../services/userService');

const userController = {
  registerUser: async (req, res, next) => {
    try {
      const newUser = await userService.createUser(req.user.uid, req.body);
      res.status(201).json(newUser);
    } catch (error) {
      next(error);
    }
  },

  getOwnProfile: async (req, res, next) => {
    try {
      const user = await userService.getUser(req.user.uid);
      if (!user) return res.status(404).json({ error: 'User profile not found' });
      res.json(user);
    } catch (error) {
      next(error);
    }
  },

  updateProfile: async (req, res, next) => {
    try {
      const updatedUser = await userService.updateUser(req.user.uid, req.body);
      res.json(updatedUser);
    } catch (error) {
      next(error);
    }
  },

  updateLocation: async (req, res, next) => {
    try {
      await userService.updateLocation(req.user.uid, req.body.location);
      res.status(200).json({ message: 'Location updated successfully' });
    } catch (error) {
      next(error);
    }
  },

  blockUser: async (req, res, next) => {
    try {
      await userService.blockUser(req.user.uid, req.body.blocked_id);
      res.status(200).json({ message: 'User blocked successfully' });
    } catch (error) {
      if (error.message === 'CANNOT_BLOCK_SELF') {
        return res.status(400).json({ error: 'You cannot block yourself' });
      }
      next(error);
    }
  },

  unblockUser: async (req, res, next) => {
    try {
      await userService.unblockUser(req.user.uid, req.params.id);
      res.status(200).json({ message: 'User unblocked successfully' });
    } catch (error) {
      next(error);
    }
  },

  deleteAccount: async (req, res, next) => {
    try {
      await userService.deleteUser(req.user.uid);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },

  getPublicProfile: async (req, res, next) => {
    try {
      const user = await userService.getPublicUser(req.params.id, req.user.uid);
      if (!user) return res.status(404).json({ error: 'User not found' });
      res.json(user);
    } catch (error) {
      next(error);
    }
  },

  getBadges: async (req, res, next) => {
    try {
      const badges = await userService.getUnreadCounts(req.user.uid);
      res.json(badges);
    } catch (error) {
      next(error);
    }
  },

  getMyGroups: async (req, res, next) => {
    try {
      const groups = await userService.getUserGroups(req.user.uid);
      res.json(groups);
    } catch (error) {
      next(error);
    }
  },

  // מענה להזמנה לקבוצה
  respondToInvitation: async (req, res, next) => {
    try {
      await userService.respondToInvitation(req.user.uid, req.params.id, req.body.status);
      res.status(200).json({ message: `Invitation ${req.body.status} successfully` });
    } catch (error) {
      if (error.message === 'INVITATION_NOT_FOUND') {
        return res.status(404).json({ error: 'Invitation not found or already processed' });
      }
      next(error);
    }
  }
};

module.exports = userController;