const { z } = require('zod');

const deviceSchema = z.object({
  device_id: z.string().min(1, "Device ID is required"),
  fcm_token: z.string().min(1, "FCM Token is required")
});

module.exports = { deviceSchema };