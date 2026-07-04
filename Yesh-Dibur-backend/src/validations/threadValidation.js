const { z } = require('zod');

const createThreadSchema = z.object({
  group_id: z.string().uuid("Invalid group ID"),
  content: z.string().min(1, "Post content cannot be empty").max(500, "Post exceeds 500 characters limit"),
  bg_type: z.enum(['image', 'color'], "Background type must be 'image' or 'color'"),
  bg_value: z.string().min(1, "Background value is required"),
  aspect_ratio: z.number().optional()
});

const createCommentSchema = z.object({
  content: z.string().min(1, "Comment cannot be empty").max(500, "Comment exceeds 500 characters limit"),
  image_url: z.string().url("Invalid image URL").optional(),
  aspect_ratio: z.number().optional()
});

module.exports = {
  createThreadSchema,
  createCommentSchema
};