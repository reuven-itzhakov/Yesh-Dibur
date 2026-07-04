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
      // הנחה שהאפליקציה שולחת את מזהה המכשיר כפרמטר בשאילתה בזמן התנתקות
      const deviceId = req.query.device_id; 
      if (!deviceId) return res.status(400).json({ error: 'Device ID is required' });
      
      await deviceService.deleteDevice(req.user.uid, deviceId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
};

module.exports = deviceController;