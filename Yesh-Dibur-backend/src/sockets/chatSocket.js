const chatSocket = (io, socket) => {
  socket.on('joinChat', (chatId) => {
    socket.join(`chat:${chatId}`);
  });

  socket.on('leaveChat', (chatId) => {
    socket.leave(`chat:${chatId}`);
  });

  socket.on('sendMessage', (data) => {
    // TODO: Validate and persist message, then broadcast
    io.to(`chat:${data.chatId}`).emit('newMessage', data);
  });

  socket.on('typing', (data) => {
    socket.to(`chat:${data.chatId}`).emit('userTyping', {
      userId: socket.user?.uid,
      chatId: data.chatId,
    });
  });
};

module.exports = chatSocket;
