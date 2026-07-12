const { auth } = require('../config/firebase');

const optionalAuthenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    req.user = null; // המשתמש מוגדר כאורח
    return next();
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await auth.verifyIdToken(token, true);
    req.user = decodedToken;
  } catch (error) {
    // אם הטוקן פג תוקף או שגוי, נתייחס אליו כאורח כדי לא להקריס את הפיד הציבורי
    req.user = null; 
  }
  next();
};

module.exports = optionalAuthenticate;