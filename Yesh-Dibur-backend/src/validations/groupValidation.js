const { z } = require('zod');

const createGroupSchema = z.object({
  name: z.string().min(2, "Name is too short").max(30, "Group name cannot exceed 30 characters"), // אכיפת 30 תווים
  description: z.string().max(500, "Description is too long").optional(),
  cover_image_url: z.string().url().optional(),
  interests: z.array(z.string()).length(5, "You must select exactly 5 interests") // אכיפת 5 תחומים בדיוק
});

const inviteSchema = z.object({
  invitee_id: z.string().min(1, "Invitee ID is required")
});

module.exports = {
  createGroupSchema,
  inviteSchema
};