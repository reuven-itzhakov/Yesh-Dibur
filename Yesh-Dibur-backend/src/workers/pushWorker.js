const { getChannel } = require('../config/rabbitmq');
const { messaging } = require('../config/firebase');

const QUEUE = 'push';

const pushWorker = {
  start: async () => {
    const channel = getChannel();
    await channel.assertQueue(QUEUE, { durable: true });

    channel.consume(QUEUE, async (msg) => {
      if (msg !== null) {
        try {
          const content = JSON.parse(msg.content.toString());
          console.log('Processing push notification:', content);

          // TODO: Implement push notification logic via Firebase Cloud Messaging

          channel.ack(msg);
        } catch (error) {
          console.error('Push worker error:', error);
          channel.nack(msg, false, false);
        }
      }
    });

    console.log('Push worker started');
  },
};

module.exports = pushWorker;