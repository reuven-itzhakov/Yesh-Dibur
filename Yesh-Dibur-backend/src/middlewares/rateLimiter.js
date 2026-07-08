const rateLimit = require('express-rate-limit');

const rateLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: true, // שולח למשתמש את מגבלת הקצב ב-Headers
  legacyHeaders: false,
  // אטימת פרצת ה-Global DoS: חילוץ ה-IP האמיתי של המשתמש העוקף את ה-Proxy (Load Balancer, Nginx, Docker)
  keyGenerator: (req) => {
    return req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.ip;
  },
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
});

module.exports = rateLimiter;
