const express = require('express');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const feedController = require('../../controllers/feedController');
const { feedPaginationSchema } = require('../../validations/feedValidation');

const router = express.Router();

router.use(authenticate);

// טאב 1: פיד הקבוצות שלי (מציג פוסטים רק מקבוצות שהמשתמש חבר בהן)
router.get('/my-groups', validate(feedPaginationSchema), feedController.getMyGroupsFeed);

// טאב 2: פיד גילוי והמלצות (מבוסס מיקום ותחומי עניין)
router.get('/discovery', validate(feedPaginationSchema), feedController.getDiscoveryFeed);

module.exports = router;