const threadService = require('../services/threadService');

const threadController = {
  getThread: async (req, res, next) => {
    try {
      // 1. קודם נשלוף את הפוסט (ונעביר את ה-UID כדי לסנן חסימות מול מחבר הפוסט ולקבל is_liked)
      const thread = await threadService.getThread(req.params.id, req.user.uid);
      if (!thread) return res.status(404).json({ error: 'Thread not found or author is blocked' });
      
      // 2. שומר סף (Gatekeeper): נוודא שלמשתמש יש הרשאה לראות את הקבוצה שהפוסט שייך אליה!
      const groupService = require('../services/groupService'); 
      const groupCheck = await groupService.getGroup(thread.group_id, req.user.uid);
      if (!groupCheck) return res.status(403).json({ error: 'Access denied to this thread (privacy or age restrictions)' });

      res.json(thread);
    } catch (error) {
      next(error);
    }
  },

  getGroupThreads: async (req, res, next) => {
    try {
      // 1. שומר סף (Gatekeeper): נוודא שלמשתמש מותר בכלל לראות את הקבוצה הזו (הגנת גילאים וחסימות)
      const groupService = require('../services/groupService'); // ייבוא פנימי למניעת מעגל תלויות
      const groupCheck = await groupService.getGroup(req.params.id, req.user.uid);
      
      if (!groupCheck) {
        return res.status(403).json({ error: 'Access denied to group content (privacy or age restrictions)' });
      }

      // 2. רק אם עברנו את חומת האבטחה, נשלוף את הפוסטים
      const threads = await threadService.getGroupThreads(req.params.id, req.user.uid);
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
      if (error.message === 'NOT_AUTHORIZED') {
        return res.status(403).json({ error: 'Not authorized, not a member, or thread deleted' });
      }
      next(error);
    }
  },

  getComments: async (req, res, next) => {
    try {
      // חובה להעביר את מזהה המשתמש המבקש כדי לסנן תגובות של אנשים חסומים
      const comments = await threadService.getComments(req.params.id, req.user.uid);
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
      if (error.message === 'NOT_AUTHORIZED') {
        return res.status(403).json({ error: 'You must be a member of the group to comment' });
      }
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