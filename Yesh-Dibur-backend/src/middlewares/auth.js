const { auth } = require('../config/firebase');

const authenticate = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    // אטימת פרצת משתמשי הרפאים (Zombie Users):
    // הוספת 'true' מכריחה את השרת לוודא שהטוקן לא בוטל, ושהמשתמש לא נמחק או נחסם ב-Firebase!
    const decodedToken = await auth.verifyIdToken(token, true);
    req.user = decodedToken;
    next();
  } catch (error) {
    if (error.code === 'auth/id-token-revoked') {
      return res.status(401).json({ error: 'Token has been revoked. Please reauthenticate.' });
    }
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

module.exports = authenticate;
