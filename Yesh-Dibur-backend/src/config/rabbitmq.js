const amqp = require('amqplib');

let channel = null;

const connectRabbitMQ = async () => {
  try {
    const connection = await amqp.connect(process.env.RABBITMQ_URI);
    channel = await connection.createChannel();
    
    // אטימת באג ההתראות האבודות: חובה לוודא שהתור קיים לפני שזורקים אליו משימות!
    await channel.assertQueue('push', { durable: true });
    
    // התאוששות קריטית במקרה של ניתוק פתאומי משירות ה-RabbitMQ
    connection.on('error', (err) => {
      console.error('RabbitMQ connection error:', err.message);
    });
    
    connection.on('close', () => {
      console.error('RabbitMQ connection closed. Exiting process to trigger auto-restart...');
      process.exit(1); // גורם ל-PM2 או Docker להרים את השרת מחדש בבטחה עם חיבור טרי
    });

    console.log('RabbitMQ connected');
    return channel;
  } catch (error) {
    console.error(`RabbitMQ connection error: ${error.message}`);
    process.exit(1);
  }
};

const getChannel = () => channel;

module.exports = { connectRabbitMQ, getChannel };
