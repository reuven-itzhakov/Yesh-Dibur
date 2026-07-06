const chatService = require('../services/chatService');
const { getChannel } = require('../config/rabbitmq'); // ייבוא ערוץ התקשורת של ראביט

const chatSocket = (io, socket) => {
  
  socket.on('joinChat', async (chatId) => {
    try {
      // מוודאים שהמשתמש הוא אכן חלק מהשיחה לפני שפותחים לו את צינור ההאזנה!
      const isMember = await chatService.verifyParticipant(chatId, socket.user.uid);
      if (isMember) {
        socket.join(`chat:${chatId}`);
        console.log(`User ${socket.user.uid} joined chat ${chatId}`);
      }
    } catch (err) {
      console.error('Socket join error:', err.message);
    }
  });

  socket.on('leaveChat', (chatId) => {
    socket.leave(`chat:${chatId}`);
    console.log(`User ${socket.user.uid} left chat ${chatId}`);
  });

  socket.on('sendMessage', async (data, callback) => {
    try {
      // מניעת קריסות שרת במקרה שמשתמש שולח אובייקט במקום מחרוזת (הגנת Type Safety)
      const content = typeof data.content === 'string' ? data.content.trim() : '';

      if (!data.chatId || !data.receiverId || (!content && !data.imageUrl)) {
        if (typeof callback === 'function') {
          callback({ status: 'error', error: 'Message must contain valid text or an image' });
        }
        return;
      }

      // הגבלת אורך ההודעה
      if (content.length > 1000) {
        if (typeof callback === 'function') {
          callback({ status: 'error', error: 'Message content exceeds the maximum length limit' });
        }
        return;
      }

      // שמירה ישירה למסד הנתונים
      const savedMessage = await chatService.saveMessage(
        socket.user.uid,
        data.receiverId,
        data.chatId,
        content,
        data.imageUrl || null,
        data.aspectRatio || null
      );

      // שידור ההודעה לחדר, חובה להשתמש ב-socket.to כדי לא להחזיר את ההודעה לשולח ולמנוע כפילות במסך
      socket.to(`chat:${data.chatId}`).emit('newMessage', savedMessage);

      // שליחת משימה לתור ההתראות ב-RabbitMQ (Offline Push Notifications)
      const channel = getChannel();
      if (channel) {
        const pushPayload = {
          type: 'new_message',
          chatId: data.chatId,
          senderId: socket.user.uid,
          receiverId: data.receiverId,
          content: content || '📷 תמונה חדשה', // שימוש בתוכן הנקי והבטוח
          timestamp: new Date().toISOString()
        };
        
        channel.publish('', 'push', Buffer.from(JSON.stringify(pushPayload)));
      }

      // אישור קבלה חיובי ללקוח (ACK) כדי שיוכל לעדכן את מסך הצ'אט המקומי שלו
      if (typeof callback === 'function') {
        callback({ status: 'ok', data: savedMessage });
      }
      
    } catch (error) {
      console.error('Send message error:', error.message);
      if (typeof callback === 'function') {
        const errMsg = error.message === 'BLOCKED_OR_UNAUTHORIZED' 
          ? 'Cannot send message. User is unavailable or you are not part of this chat.' 
          : 'Internal server error while saving message';
        callback({ status: 'error', error: errMsg });
      }
    }
  });

  socket.on('typing', async (data) => {
    try {
      // מניעת ספאם והטרדות: מוודאים שהמשתמש באמת בשיחה לפני שמשדרים "מקליד/ה..."
      const isMember = await chatService.verifyParticipant(data.chatId, socket.user.uid);
      if (isMember) {
        socket.to(`chat:${data.chatId}`).emit('userTyping', {
          userId: socket.user.uid,
          chatId: data.chatId,
        });
      }
    } catch (err) {
      console.error('Typing event error:', err.message);
    }
  });

  socket.on('markAsRead', async (data) => {
    try {
      if (data.chatId) {
        // עדכון מסד הנתונים מאחורי הקלעים
        await chatService.markMessagesAsRead(data.chatId, socket.user.uid);
        
        // שידור אירוע לשולח כדי שהוי הכחול (או סטטוס 'נקרא') יתעדכן מיד במסך שלו!
        socket.to(`chat:${data.chatId}`).emit('messagesRead', {
          chatId: data.chatId,
          readBy: socket.user.uid
        });
      }
    } catch (err) {
      console.error('Mark as read socket error:', err.message);
    }
  });
};

module.exports = chatSocket;