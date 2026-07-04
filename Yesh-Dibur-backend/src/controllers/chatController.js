const chatService = require('../services/chatService');

const chatController = {
  getChats: async (req, res, next) => {
    try {
      const chats = await chatService.getUserChats(req.user.uid);
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
      // טיפול במקרה קצה שבו משתמש מנסה לפתוח שיחה עם עצמו
      if (error.message === 'CANNOT_CHAT_WITH_SELF') {
        return res.status(400).json({ error: 'You cannot create a chat with yourself.' });
      }
      next(error);
    }
  },

  getChatMessages: async (req, res, next) => {
    try {
      const messages = await chatService.getChatMessages(req.params.id, req.user.uid);
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