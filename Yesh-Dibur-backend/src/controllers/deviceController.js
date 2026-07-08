const deviceService = require('../services/deviceService');

const deviceController = {
  registerDevice: async (req, res, next) => {
    try {
      const { device_id, fcm_token } = req.body;
      await deviceService.upsertDevice(req.user.uid, device_id, fcm_token);
      res.status(200).json({ message: 'Device registered successfully' });
    } catch (error) {
      next(error);
    }
  },

  removeDevice: async (req, res, next) => {
    try {
      // חסימת קריסת שרת במקרה של שליחת מערך בשורת הכתובת (Query Array Injection)
      let deviceId = req.query.device_id; 
      if (Array.isArray(deviceId)) deviceId = deviceId[0];
      
      if (!deviceId || typeof deviceId !== 'string' || deviceId.trim() === '') {
        return res.status(400).json({ error: 'Valid Device ID is required' });
      }
      
      await deviceService.deleteDevice(req.user.uid, deviceId.trim());
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
};

module.exports = deviceController;