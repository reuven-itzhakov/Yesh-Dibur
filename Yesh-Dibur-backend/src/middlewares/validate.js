const validate = (schema) => (req, res, next) => {
  try {
    // Zod משתמש בפונקציה parse במקום validate
    req.body = schema.parse(req.body);
    next();
  } catch (error) {
    // אטימת מיסוך שגיאות: אם השגיאה היא שגיאת וולידציה של Zod, נחזיר 400 מסודר למפתח הלקוח
    if (error.name === 'ZodError') {
      return res.status(400).json({ error: error.errors });
    }
    // אם זו שגיאת שרת אחרת, נעביר אותה הלאה
    next(error); 
  }
};

module.exports = validate;