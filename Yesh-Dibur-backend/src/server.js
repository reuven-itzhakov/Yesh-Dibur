const http = require('http');
const { Server } = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter'); 
const dotenv = require('dotenv');

function getLocalIpAddress() {
  const os = require('os');
  const interfaces = os.networkInterfaces();
  let fallbackIp = 'localhost';

  for (const interfaceName in interfaces) {
    // דילוג על כרטיסי רשת וירטואליים של Hyper-V, WSL או Docker
    if (interfaceName.toLowerCase().includes('vethernet') || interfaceName.toLowerCase().includes('wsl')) {
      continue;
    }

    for (const iface of interfaces[interfaceName]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        // עדיפות עליונה לטווח הכתובות הביתי הנפוץ (Wi-Fi / Ethernet אמיתי)
        if (iface.address.startsWith('192.168.')) {
          return iface.address;
        }
        // שומרים כתובת אחרת לגיבוי למקרה שאין 192.168 (למשל ב-Production בענן)
        fallbackIp = iface.address;
      }
    }
  }
  return fallbackIp;
}

dotenv.config();

const app = require('./app');
const { pool, connectDB } = require('./config/db');
const { redisClient, connectRedis } = require('./config/redis');
const { connectRabbitMQ, getChannel } = require('./config/rabbitmq');
require('./config/firebase');
const socketManager = require('./sockets/socketManager');
const moderationWorker = require('./workers/moderationWorker');
const pushWorker = require('./workers/pushWorker');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '127.0.0.1';

const startServer = async () => {
  try {
    // 1. חיבור לתשתיות הליבה
    await connectDB();
    await connectRabbitMQ();
    await connectRedis(); 

    const server = http.createServer(app);

    // 2. הגדרת שרת ה-WebSockets עם אבטחת CORS בסיסית
    const io = new Server(server, {
      cors: {
        origin: process.env.CLIENT_URL || '*',
        methods: ['GET', 'POST'],
      },
    });

    // 3. חיבור ה-Redis Adapter לטובת סקליביליטי ומניעת ניתוקים כפי שאופיין
    const pubClient = redisClient;
    const subClient = redisClient.duplicate();
    await subClient.connect();
    io.adapter(createAdapter(pubClient, subClient));

    // 4. איתחול מנהל הסוקטים והרצת ה-Workers ברקע
    socketManager(io);
    await moderationWorker.start();
    await pushWorker.start();

    const runningServer = server.listen(PORT, HOST, () => {
      if (HOST === '0.0.0.0') {
        const localIp = getLocalIpAddress();
        console.log(`Server running on port http://${localIp}:${PORT}`);
      }
      else {
        console.log(`Server running on port http://localhost:${PORT}`);
      }
    });

    // 5. מנגנון כיבוי אלגנטי (Graceful Shutdown) המונע השחתת נתונים
    const shutdown = async (signal) => {
      console.log(`Received ${signal}, starting graceful shutdown...`);
      
      runningServer.close(async () => {
        console.log('HTTP server closed.');
        
        try {
          // סגירת ערוץ וחיבור RabbitMQ
          const channel = getChannel();
          if (channel) {
            await channel.close();
            console.log('RabbitMQ channel closed.');
          }
          
          // סגירת חיבורי ה-Redis
          await pubClient.quit();
          await subClient.quit();
          console.log('Redis connections closed.');

          // סגירת חיבורי ה-PostgreSQL Pool
          await pool.end();
          console.log('PostgreSQL pool ended.');

          console.log('Graceful shutdown completed successfully.');
          process.exit(0);
        } catch (err) {
          console.error('Error during graceful shutdown:', err);
          process.exit(1);
        }
      });

      // הגבלת זמן מקסימלית לסגירה (Timeout) כדי שהשרת לא יתקע באוויר
      setTimeout(() => {
        console.error('Forced shutdown due to timeout.');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

    // אטימת קריסות פתאומיות: מניעת מצב "זומבי" והשחתת נתונים במקרה של שגיאת קוד לא צפויה
    process.on('uncaughtException', (err) => {
      console.error('CRITICAL ERROR: Uncaught Exception:', err);
      shutdown('UNCAUGHT_EXCEPTION');
    });

    process.on('unhandledRejection', (reason, promise) => {
      console.error('CRITICAL ERROR: Unhandled Rejection at:', promise, 'reason:', reason);
      shutdown('UNHANDLED_REJECTION');
    });

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();