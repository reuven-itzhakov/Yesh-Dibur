const express = require('express');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const deviceController = require('../../controllers/deviceController');
const { deviceSchema } = require('../../validations/deviceValidation');

const router = express.Router();

// כל נתיבי המכשירים דורשים אימות
router.use(authenticate);

// רישום מכשיר חדש לקבלת פוש
router.post('/', validate(deviceSchema), deviceController.registerDevice);

// מחיקת מכשיר (למשל בעת התנתקות מהאפליקציה)
router.delete('/', deviceController.removeDevice);

module.exports = router;