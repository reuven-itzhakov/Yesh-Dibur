const express = require('express');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const groupController = require('../../controllers/groupController');
const threadController = require('../../controllers/threadController'); // הייבוא החדש
const { createGroupSchema, inviteSchema } = require('../../validations/groupValidation');

const router = express.Router();

// כל נתיבי הקבוצות דורשים אימות טוקן
router.use(authenticate);

// פעולות ליבה על הקבוצה
router.post('/', validate(createGroupSchema), groupController.createGroup);
router.get('/:id', groupController.getGroup);
router.put('/:id', validate(createGroupSchema.partial()), groupController.updateGroup);
router.delete('/:id', groupController.deleteGroup);

// פעולות חברתיות של משתמשים מול הקבוצה
router.post('/:id/join', groupController.joinGroup);
router.post('/:id/leave', groupController.leaveGroup);
router.post('/:id/invite', validate(inviteSchema), groupController.inviteUser);

// הנתיב החדש: שליפת הפוסטים (אשכולות) תחת קבוצה ספציפית
router.get('/:id/threads', threadController.getGroupThreads);

module.exports = router;