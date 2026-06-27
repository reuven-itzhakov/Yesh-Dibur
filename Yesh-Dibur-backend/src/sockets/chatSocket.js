// בעתיד נייבא לכאן את ה-Service שיכתוב למסד הנתונים:
// const chatService = require('../services/chatService');

const chatSocket = (io, socket) => {
  
  socket.on('joinChat', (chatId) => {
    socket.join(`chat:${chatId}`);
    console.log(`User ${socket.user.uid} joined chat ${chatId}`);
  });

  socket.on('leaveChat', (chatId) => {
    socket.leave(`chat:${chatId}`);
    console.log(`User ${socket.user.uid} left chat ${chatId}`);
  });

  // הוספת מנגנון Acknowledgement (ACK) בעזרת פרמטר callback
  socket.on('sendMessage', async (data, callback) => {
    try {
      // וולידציה בסיסית
      if (!data.chatId || !data.content) {
        if (typeof callback === 'function') {
          callback({ status: 'error', error: 'Missing required fields' });
        }
        return;
      }

      // TODO: כאן תיכנס הלוגיקה של שמירת ההודעה למסד הנתונים (PostgreSQL)
      // const savedMessage = await chatService.saveMessage({
      //   senderId: socket.user.uid,
      //   conversationId: data.chatId,
      //   content: data.content
      // });
      
      // אובייקט זמני עד שנחבר את מסד הנתונים
      const messagePayload = {
        id: 'temp-db-id', // יוחלף ב-ID האמיתי ממסד הנתונים
        senderId: socket.user.uid,
        chatId: data.chatId,
        content: data.content,
        createdAt: new Date().toISOString()
      };

      // שידור ההודעה לכל מי שמחובר לחדר הספציפי הזה
      io.to(`chat:${data.chatId}`).emit('newMessage', messagePayload);

      // החזרת אישור קבלה חיובי ל-Flutter כדי שיוריד את אייקון ה"נשלח..." (V בודד)
      if (typeof callback === 'function') {
        callback({ status: 'ok', data: messagePayload });
      }
      
    } catch (error) {
      console.error('Send message error:', error.message);
      
      // החזרת שגיאה חזרה לאפליקציה כדי שתציג כפתור "נסה שוב"
      if (typeof callback === 'function') {
        callback({ status: 'error', error: 'Internal server error while saving message' });
      }
    }
  });

  socket.on('typing', (data) => {
    // שליחת אירוע "מקליד" לכולם בחדר, חוץ מלמי ששלח את האירוע
    socket.to(`chat:${data.chatId}`).emit('userTyping', {
      userId: socket.user.uid,
      chatId: data.chatId,
    });
  });
};

module.exports = chatSocket;