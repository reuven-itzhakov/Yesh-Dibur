const chatService = require('../services/chatService');
const { getChannel } = require('../config/rabbitmq'); // ייבוא ערוץ התקשורת של ראביט

const chatSocket = (io, socket) => {
  
  socket.on('joinChat', (chatId) => {
    socket.join(`chat:${chatId}`);
    console.log(`User ${socket.user.uid} joined chat ${chatId}`);
  });

  socket.on('leaveChat', (chatId) => {
    socket.leave(`chat:${chatId}`);
    console.log(`User ${socket.user.uid} left chat ${chatId}`);
  });

  socket.on('sendMessage', async (data, callback) => {
    try {
      if (!data.chatId || !data.content || !data.receiverId) {
        if (typeof callback === 'function') {
          callback({ status: 'error', error: 'Missing required fields' });
        }
        return;
      }

      // שמירה ישירה למסד הנתונים
      const savedMessage = await chatService.saveMessage(
        socket.user.uid,
        data.receiverId,
        data.chatId,
        data.content,
        data.imageUrl || null,
        data.aspectRatio || null
      );

      // שידור ההודעה לחדר
      io.to(`chat:${data.chatId}`).emit('newMessage', savedMessage);

      // שליחת משימה לתור ההתראות ב-RabbitMQ (Offline Push Notifications)
      const channel = getChannel();
      if (channel) {
        const pushPayload = {
          type: 'new_message',
          chatId: data.chatId,
          senderId: socket.user.uid,
          receiverId: data.receiverId,
          content: data.content,
          timestamp: new Date().toISOString()
        };
        
        // זריקת המשימה לתור שנקרא 'push'
        channel.publish('', 'push', Buffer.from(JSON.stringify(pushPayload)));
      }

      // אישור קבלה חיובי ללקוח (ACK)
      if (typeof callback === 'function') {
        callback({ status: 'ok', data: savedMessage });
      }
      
    } catch (error) {
      console.error('Send message error:', error.message);
      if (typeof callback === 'function') {
        callback({ status: 'error', error: 'Internal server error while saving message' });
      }
    }
  });

  socket.on('typing', (data) => {
    socket.to(`chat:${data.chatId}`).emit('userTyping', {
      userId: socket.user.uid,
      chatId: data.chatId,
    });
  });
};

module.exports = chatSocket;