const express = require('express');
const router = express.Router();
const userController = require('../../controllers/userController');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const { 
  registerSchema, 
  updateProfileSchema, 
  updateLocationSchema, 
  blockUserSchema,
  respondInvitationSchema
} = require('../../validations/userValidation');

router.post('/register', authenticate, validate(registerSchema), userController.registerUser);

router.get('/profile', authenticate, userController.getOwnProfile);
router.put('/profile', authenticate, validate(updateProfileSchema), userController.updateProfile);
router.delete('/profile', authenticate, userController.deleteAccount);

// עדכון מיקום GPS בזמן אמת
router.put('/location', authenticate, validate(updateLocationSchema), userController.updateLocation);

// ניהול חסימות
router.post('/block', authenticate, validate(blockUserSchema), userController.blockUser);
router.delete('/block/:id', authenticate, userController.unblockUser);

router.get('/badges', authenticate, userController.getBadges);
router.get('/groups', authenticate, userController.getMyGroups);
router.put('/invitations/:id/respond', authenticate, validate(respondInvitationSchema), userController.respondToInvitation);
router.get('/:id', authenticate, userController.getPublicProfile);


module.exports = router;