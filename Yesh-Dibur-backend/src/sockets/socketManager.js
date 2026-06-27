const chatSocket = require('./chatSocket');

const socketManager = (io) => {
  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    // Authenticate socket
    socket.on('authenticate', (data) => {
      // TODO: Verify Firebase token and join user rooms
    });

    // Chat events
    chatSocket(io, socket);

    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.id}`);
    });
  });
};

module.exports = socketManager;
