const http = require('http');
const { Server } = require('socket.io');
// במידה ואתה משתמש ב-Redis Adapter כפי שאופיין, תזדקק לייבוא הזה:
// const { createAdapter } = require('@socket.io/redis-adapter'); 
const dotenv = require('dotenv');

dotenv.config();

const app = require('./app');
const { connectDB } = require('./config/db');
const { connectRedis } = require('./config/redis');
const { connectRabbitMQ } = require('./config/rabbitmq');
require('./config/firebase');
const socketManager = require('./sockets/socketManager');
const moderationWorker = require('./workers/moderationWorker');
const pushWorker = require('./workers/pushWorker');

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await connectDB();
    await connectRabbitMQ();
    
    // אם הגדרת את Redis Adapter, הפונקציה שלך אמורה להחזיר pubClient ו-subClient
    // const { pubClient, subClient } = await connectRedis();
    await connectRedis(); 

    const server = http.createServer(app);

    const io = new Server(server, {
      cors: {
        origin: process.env.CLIENT_URL || '*',
        methods: ['GET', 'POST'],
      },
    });

    // חיבור ה-Redis Adapter ל-Socket.io
    // io.adapter(createAdapter(pubClient, subClient));

    socketManager(io);

    moderationWorker.start();
    pushWorker.start();

    const runningServer = server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });

    const shutdown = async () => {
      console.log('Received kill signal, shutting down gracefully...');
      
      runningServer.close(() => {
        console.log('Closed out remaining HTTP connections.');
      });

      // כאן המקום להוסיף את פונקציות הסגירה של התשתיות שלך
      // await rabbitChannel.close();
      
      process.exit(0);
    };

    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();