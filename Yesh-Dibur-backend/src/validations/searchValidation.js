const { z } = require('zod');

const searchSchema = z.object({
  q: z.string().optional().or(z.literal('')),
  type: z.enum(['users', 'groups', 'all']).default('all').optional().or(z.literal('')).transform(val => (!val ? 'all' : val)),
  page: z.string().regex(/^\d+$/).optional().or(z.literal('')).transform(val => (!val ? 1 : Number(val))),
  limit: z.string().regex(/^\d+$/).optional().or(z.literal('')).transform(val => (!val ? 20 : Number(val))),
  radius_km: z.string().regex(/^\d+$/).optional().or(z.literal('')).transform(val => (!val ? undefined : Number(val))),
  lat: z.string().regex(/^-?\d+(\.\d+)?$/).optional().or(z.literal('')).transform(val => (!val ? undefined : Number(val))),
  lng: z.string().regex(/^-?\d+(\.\d+)?$/).optional().or(z.literal('')).transform(val => (!val ? undefined : Number(val))),
  min_age: z.string().regex(/^\d+$/).optional().or(z.literal('')).transform(val => (!val ? undefined : Number(val))),
  max_age: z.string().regex(/^\d+$/).optional().or(z.literal('')).transform(val => (!val ? undefined : Number(val))),
  interests: z.string().optional().or(z.literal(''))
});

module.exports = {
  searchSchema
};