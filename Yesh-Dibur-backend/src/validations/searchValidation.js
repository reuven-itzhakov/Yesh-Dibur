const { z } = require('zod');

const searchSchema = z.object({
  q: z.string().optional(),
  type: z.enum(['users', 'groups', 'all']).default('all'),
  page: z.string().regex(/^\d+$/).transform(Number).default('1'),
  limit: z.string().regex(/^\d+$/).transform(Number).default('20'),
  radius_km: z.string().regex(/^\d+$/).transform(Number).optional(),
  lat: z.string().regex(/^-?\d+(\.\d+)?$/).transform(Number).optional(), // קו רוחב אופציונלי לעיר
  lng: z.string().regex(/^-?\d+(\.\d+)?$/).transform(Number).optional(), // קו אורך אופציונלי לעיר
  min_age: z.string().regex(/^\d+$/).transform(Number).optional(),
  max_age: z.string().regex(/^\d+$/).transform(Number).optional(),
  interests: z.string().optional()
});

module.exports = {
  searchSchema
};