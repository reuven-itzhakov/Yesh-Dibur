const chatSocket = require('./chatSocket');
const { auth } = require('../config/firebase');

const socketManager = (io) => {
  // אימות בשלב ה-Handshake (לפני יצירת החיבור בפועל)
  // אימות בשלב ה-Handshake (לפני יצירת החיבור בפועל)
  io.use(async (socket, next) => {
    try {
      // שליפת הטוקן מתוך פרמטרי ההתחברות שהלקוח שולח
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization;
      
      if (!token) {
        return next(new Error('Authentication error: No token provided'));
      }

      // ניקוי הקידומת במקרה שהיא נשלחה
      const actualToken = token.startsWith('Bearer ') ? token.split(' ')[1] : token;

      // אטימת פרצת חיבורי הרפאים (Zombie Sockets):
      // הוספת 'true' מכריחה את השרת לוודא בזמן אמת שהטוקן לא בוטל ושהמשתמש לא נחסם ב-Firebase!
      const decodedToken = await auth.verifyIdToken(actualToken, true);
      
      // הצמדת פרטי המשתמש לאובייקט הסוקט כדי שיהיו זמינים בכל האירועים
      socket.user = decodedToken;
      next();
    } catch (error) {
      console.error('Socket authentication failed:', error.message);
      if (error.code === 'auth/id-token-revoked') {
        return next(new Error('Authentication error: Token has been revoked.'));
      }
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`User connected to Yesh Dibur: ${socket.id}, UID: ${socket.user.uid}`);

    // הפעלת אירועי הצ'אט והעברת אובייקט הסוקט המאומת
    chatSocket(io, socket);

    socket.on('disconnect', (reason) => {
      console.log(`User disconnected (UID: ${socket.user.uid}), Reason: ${reason}`);
    });
  });
};

module.exports = socketManager;