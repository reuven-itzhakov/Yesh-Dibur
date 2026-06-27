const { z } = require('zod');

const registerSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters").max(50),
  email: z.string().email("Invalid email address"),
  phone: z.string().min(9, "Invalid phone number"), // וולידציה בסיסית למספר טלפון
  birth_date: z.string().datetime(), // מוודא פורמט ISO תקין (לחישוב קטין/בגיר ברקע)
  city: z.string().min(2, "City name must be valid"), // לטובת שירות ה-Geocoding
  bio: z.string().max(500).optional(),
  instagram_url: z.string().url().optional().or(z.literal('')),
  tiktok_url: z.string().url().optional().or(z.literal('')),
  profile_image_url: z.string().url().optional(),
  interests: z.array(z.string()).length(5, "You must select exactly 5 interests") // אכיפת ה-5 בדיוק מהאפיון
});

const updateProfileSchema = z.object({
  name: z.string().min(2).max(50).optional(),
  city: z.string().min(2).optional(),
  bio: z.string().max(500).optional(),
  instagram_url: z.string().url().optional().or(z.literal('')),
  tiktok_url: z.string().url().optional().or(z.literal('')),
  profile_image_url: z.string().url().optional(),
  interests: z.array(z.string()).length(5, "You must select exactly 5 interests").optional()
});

module.exports = {
  registerSchema,
  updateProfileSchema
};