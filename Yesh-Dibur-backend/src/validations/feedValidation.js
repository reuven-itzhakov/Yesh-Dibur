const { z } = require('zod');

const feedPaginationSchema = z.object({
  // תמיכה במחרוזת ריקה מהאפליקציה בטעינה ראשונה
  cursor: z.string().datetime().optional().or(z.literal('')), 
  limit: z.string().regex(/^\d+$/).optional().or(z.literal('')).transform(val => (!val ? 20 : Number(val))), 
  radius_km: z.string().regex(/^\d+$/).optional().or(z.literal('')).transform(val => (!val ? 10 : Number(val)))
});

module.exports = {
  feedPaginationSchema
};
