const validate = (schema) => (req, res, next) => {
  try {
    // Zod משתמש בפונקציה parse במקום validate
    req.body = schema.parse(req.body);
    next();
  } catch (error) {
    // מעביר את השגיאה (שתזוהה כ-ZodError) לטיפול השגיאות הגלובלי שלנו
    next(error); 
  }
};

module.exports = validate;