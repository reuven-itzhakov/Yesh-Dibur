const express = require('express');
const authenticate = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const searchController = require('../../controllers/searchController');
const { searchSchema } = require('../../validations/searchValidation');

const router = express.Router();

router.use(authenticate);

// נתיב החיפוש המרכזי (תומך ב-Query Parameters)
router.get('/', validate(searchSchema), searchController.search);

module.exports = router;