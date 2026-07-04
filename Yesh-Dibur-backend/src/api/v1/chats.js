const express = require('express');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const chatController = require('../../controllers/chatController');
const { createChatSchema } = require('../../validations/chatValidation');

const router = express.Router();

router.use(authenticate);

// שליפת רשימת תיבות השיחה (Inbox)
router.get('/', chatController.getChats);

// יצירת תיבת שיחה חדשה מול משתמש אחר
router.post('/', validate(createChatSchema), chatController.createChat);

// שליפת היסטוריית ההודעות בתוך שיחה ספציפית
router.get('/:id/messages', chatController.getChatMessages);

// אישור בקשת שיחה (העברת הודעות מסטטוס 'ממתין' ל'מאושר')
router.put('/:id/approve', chatController.approveChat);

// סימון הודעות כנקראו בתוך שיחה ספציפית (איפוס מונה ההתראות)
router.put('/:id/read', chatController.markAsRead);

module.exports = router;