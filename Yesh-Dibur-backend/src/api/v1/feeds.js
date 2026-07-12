const express = require('express');
const authenticate = require('../../middlewares/auth');
const optionalAuthenticate = require('../../middlewares/optionalAuth');
const feedController = require('../../controllers/feedController');

const router = express.Router();

// טאב 1: פיד הקבוצות שלי (מחייב משתמש רשום!)
router.get('/my-groups', authenticate, feedController.getMyGroupsFeed);

// טאב 2: פיד גילוי והמלצות (פתוח גם לאורחים)
router.get('/discovery', optionalAuthenticate, feedController.getDiscoveryFeed);

module.exports = router;