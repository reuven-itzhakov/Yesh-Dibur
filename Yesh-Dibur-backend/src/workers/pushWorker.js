const { getChannel } = require('../config/rabbitmq');
const { messaging } = require('../config/firebase');

const QUEUE = 'push';
const DLQ = 'push_dlq';
const MAX_RETRIES = 3;

const pushWorker = {
  start: async () => {
    const channel = getChannel();
    
    if (!channel) {
      console.error('RabbitMQ channel is not initialized.');
      return;
    }

    await channel.assertQueue(QUEUE, { durable: true });
    await channel.assertQueue(DLQ, { durable: true });

    channel.consume(QUEUE, async (msg) => {
      if (msg !== null) {
        try {
          const content = JSON.parse(msg.content.toString());
          console.log('Processing push notification:', content);

          // TODO: Implement push notification logic via Firebase Cloud Messaging (FCM)
          // const response = await messaging.send(payload);

          channel.ack(msg);
        } catch (error) {
          console.error('Push worker error:', error.message);
          
          const headers = msg.properties.headers || {};
          const retryCount = (headers['x-retries'] || 0) + 1;

          if (retryCount <= MAX_RETRIES) {
            console.log(`Retrying push notification, attempt ${retryCount} of ${MAX_RETRIES}`);
            
            channel.publish('', QUEUE, msg.content, {
              headers: { ...headers, 'x-retries': retryCount }
            });
          } else {
            console.log('Max retries reached. Moving message to DLQ (Push).');
            channel.publish('', DLQ, msg.content);
          }
          
          channel.ack(msg);
        }
      }
    });

    console.log('Push worker started and listening for tasks');
  },
};

module.exports = pushWorker;