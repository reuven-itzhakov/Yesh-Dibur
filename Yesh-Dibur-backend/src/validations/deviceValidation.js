const { z } = require('zod');

const deviceSchema = z.object({
  device_id: z.string().trim().min(1, "Device ID is required").max(255, "Device ID is too long"),
  fcm_token: z.string().trim().min(1, "FCM Token is required").max(1024, "FCM Token is too long")
});

module.exports = { deviceSchema };