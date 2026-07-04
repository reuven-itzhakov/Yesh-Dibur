const { z } = require('zod');

const createChatSchema = z.object({
  receiver_id: z.string().min(1, "Receiver ID is required")
});

module.exports = {
  createChatSchema
};