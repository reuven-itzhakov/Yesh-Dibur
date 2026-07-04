const express = require('express');
const router = express.Router();
const userController = require('../../controllers/userController');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const { registerSchema, updateProfileSchema } = require('../../validations/userValidation');
const deviceController = require('../../controllers/deviceController');
const { deviceSchema } = require('../../validations/deviceValidation');

// 1. הרשמה - משתמש בשער הגנה של וולידציית קלט בלבד (האימות הראשוני מבוצע מול Firebase בלקוח)
router.post('/register', authenticate, validate(registerSchema), userController.registerUser);

// 2. נתיבים מוגנים - דורשים חומת אימות טוקן (authenticate)
router.get('/profile', authenticate, userController.getOwnProfile);
router.put('/profile', authenticate, validate(updateProfileSchema), userController.updateProfile);
router.delete('/profile', authenticate, userController.deleteAccount); // מחיקה רכה

// 3. שליפת פרופיל של משתמש אחר (ציבורי)
router.get('/:id', authenticate, userController.getPublicProfile);

// 4. מוני התראות ובאדג'ים
router.get('/badges', authenticate, userController.getBadges);

// 5. קבוצות שהמשתמש חבר בהן
router.get('/groups', authenticate, userController.getMyGroups);

// ניהול מכשירים (Push Notifications)
router.post('/device', validate(deviceSchema), deviceController.registerDevice);
router.delete('/device', deviceController.removeDevice);

module.exports = router;