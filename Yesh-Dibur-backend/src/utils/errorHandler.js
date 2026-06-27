const logger = require('./logger');

const errorHandler = (err, req, res, next) => {
  logger.error(err.stack || err.message);

  // זיהוי אוטומטי של שגיאות וולידציה מ-Zod
  if (err.name === 'ZodError') {
    return res.status(400).json({
      error: 'Validation Error',
      details: err.errors.map(e => ({ path: e.path.join('.'), message: e.message }))
    });
  }

  // זיהוי שגיאות ייחודיות של PostgreSQL (לדוגמה קוד 23505 אומר שהמשתמש כבר קיים/כפילות)
  if (err.code === '23505') {
    return res.status(409).json({
      error: 'Conflict',
      message: 'This resource already exists in the system.'
    });
  }

  // ניהול שגיאות ידניות שזרקנו עם קוד ספציפי, אחרת ברירת המחדל היא 500
  const statusCode = err.statusCode || 500;
  
  // אם זו שגיאת 500, לא נחשוף פרטים טכניים החוצה למשתמש
  const message = statusCode === 500 ? 'Internal Server Error' : err.message;

  res.status(statusCode).json({
    error: message,
    // חשיפת ה-Stack Trace רק בפיתוח
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = errorHandler;