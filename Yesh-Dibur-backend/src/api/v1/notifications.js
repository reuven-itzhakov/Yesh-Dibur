const express = require('express');
const authenticate = require('../../middlewares/auth');
const notificationController = require('../../controllers/notificationController');

const router = express.Router();

router.use(authenticate);

router.get('/', notificationController.getNotifications);
router.put('/read-all', notificationController.markAllAsRead);

// הסרנו את ה-validate מכאן, הולידציה תתבצע בקונטרולר
router.put('/:id/read', notificationController.markAsRead);

module.exports = router;