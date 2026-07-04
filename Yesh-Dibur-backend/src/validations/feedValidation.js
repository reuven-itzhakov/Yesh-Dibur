const { z } = require('zod');

const feedPaginationSchema = z.object({
  // הסמן הוא למעשה חותמת הזמן של הפוסט האחרון שהמשתמש ראה
  cursor: z.string().datetime().optional(), 
  
  // הגבלת כמות הפריטים, ברירת מחדל 20 לפי האפיון
  limit: z.string().regex(/^\d+$/).transform(Number).default('20'), 
  
  // רדיוס החיפוש בקילומטרים (ברירת מחדל 10 ק"מ)
  radius_km: z.string().regex(/^\d+$/).transform(Number).default('10').optional()
});

module.exports = {
  feedPaginationSchema
};
