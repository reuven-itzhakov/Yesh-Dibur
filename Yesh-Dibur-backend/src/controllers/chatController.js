const chatService = require('../services/chatService');

const chatController = {
  getChats: async (req, res, next) => {
    try {
      // עימוד תיבות השיחה (Inbox) למניעת קריסה של שרת ה-Node וזיכרון האפליקציה
      const page = Math.max(parseInt(req.query.page) || 1, 1);
      const limit = Math.min(Math.max(parseInt(req.query.limit) || 20, 1), 50);
      const offset = (page - 1) * limit;

      const chats = await chatService.getUserChats(req.user.uid, limit, offset);
      res.json(chats);
    } catch (error) {
      next(error);
    }
  },

  createChat: async (req, res, next) => {
    try {
      const chat = await chatService.createConversation(req.user.uid, req.body.receiver_id);
      res.status(201).json(chat);
    } catch (error) {
      if (error.message === 'CANNOT_CHAT_WITH_SELF') {
        return res.status(400).json({ error: 'You cannot create a chat with yourself.' });
      }
      if (error.message === 'NOT_ALLOWED') {
        return res.status(403).json({ error: 'Cannot open chat due to privacy settings or age restrictions.' });
      }
      next(error);
    }
  },

  getChatMessages: async (req, res, next) => {
    try {
      // אכיפת עימוד (Pagination) כדי למנוע קריסת שרת
      const page = Math.max(parseInt(req.query.page) || 1, 1);
      const limit = Math.min(Math.max(parseInt(req.query.limit) || 20, 1), 50);
      const offset = (page - 1) * limit;

      const messages = await chatService.getChatMessages(req.params.id, req.user.uid, limit, offset);
      res.json(messages);
    } catch (error) {
      if (error.message === 'UNAUTHORIZED_ACCESS') {
        return res.status(403).json({ error: 'You are not authorized to view this chat.' });
      }
      next(error);
    }
  },

  approveChat: async (req, res, next) => {
    try {
      // המשתמש שמאשר חייב להיות המקבל של ההודעות
      await chatService.approveChat(req.params.id, req.user.uid);
      res.status(200).json({ message: 'Chat request approved successfully' });
    } catch (error) {
      next(error);
    }
  },

  markAsRead: async (req, res, next) => {
    try {
      await chatService.markMessagesAsRead(req.params.id, req.user.uid);
      res.status(200).json({ message: 'Messages marked as read' });
    } catch (error) {
      next(error);
    }
  }
};

module.exports = chatController;