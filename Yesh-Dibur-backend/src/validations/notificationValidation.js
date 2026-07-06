const { z } = require('zod');

// וולידציה לפרמטרים של שורת הכתובת (Query Parameters) עבור עימוד ההתראות
const notificationPaginationSchema = z.object({
  page: z.string().regex(/^\d+$/).transform(Number).default('1').optional(),
  limit: z.string().regex(/^\d+$/).transform(Number).default('20').optional()
});

// וולידציה למזהה התראה ספציפי שנשלח בנתיב (Path Parameter)
const notificationIdSchema = z.object({
  id: z.string().uuid("Invalid notification ID format")
});

module.exports = {
  notificationPaginationSchema,
  notificationIdSchema
};