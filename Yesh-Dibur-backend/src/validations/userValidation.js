const { z } = require('zod');

const registerSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters").max(50),
  email: z.string().email("Invalid email address"),
  phone: z.string().min(9, "Invalid phone number"),
  birth_date: z.string().datetime(),
  location: z.object({
    lat: z.number(),
    lng: z.number()
  }).optional(),
  bio: z.string().max(500).optional(),
  instagram_url: z.string().url().optional().or(z.literal('')),
  tiktok_url: z.string().url().optional().or(z.literal('')),
  profile_image_url: z.string().url().optional(),
  interests: z.array(z.string()).length(5, "You must select exactly 5 interests")
});

const updateProfileSchema = z.object({
  name: z.string().min(2).max(50).optional(),
  location: z.object({
    lat: z.number(),
    lng: z.number()
  }).optional(),
  bio: z.string().max(500).optional(),
  instagram_url: z.string().url().optional().or(z.literal('')),
  tiktok_url: z.string().url().optional().or(z.literal('')),
  profile_image_url: z.string().url().optional(),
  interests: z.array(z.string()).length(5, "You must select exactly 5 interests").optional(),
  settings: z.record(z.any()).optional() // מאפשר שמירת אובייקט הגדרות גמיש (JSONB)
});

const updateLocationSchema = z.object({
  location: z.object({
    lat: z.number(),
    lng: z.number()
  })
});

const blockUserSchema = z.object({
  blocked_id: z.string().min(1, "Blocked ID is required")
});

const respondInvitationSchema = z.object({
  status: z.enum(['approved', 'rejected'], "Status must be 'approved' or 'rejected'")
});

module.exports = {
  registerSchema,
  updateProfileSchema,
  updateLocationSchema,
  blockUserSchema,
  respondInvitationSchema
};