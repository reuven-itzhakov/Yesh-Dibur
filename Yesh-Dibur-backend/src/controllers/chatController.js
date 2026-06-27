const chatService = require('../services/chatService');

const chatController = {
  getChats: async (req, res, next) => {
    try {
      const chats = await chatService.getChats(req.query);
      res.json(chats);
    } catch (error) {
      next(error);
    }
  },

  createChat: async (req, res, next) => {
    try {
      const chat = await chatService.createChat(req.body);
      res.status(201).json(chat);
    } catch (error) {
      next(error);
    }
  },

  getChat: async (req, res, next) => {
    try {
      const chat = await chatService.getChat(req.params.id);
      if (!chat) return res.status(404).json({ error: 'Chat not found' });
      res.json(chat);
    } catch (error) {
      next(error);
    }
  },

  deleteChat: async (req, res, next) => {
    try {
      await chatService.deleteChat(req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = chatController;
