const { getChannel } = require('../config/rabbitmq');

const QUEUE = 'moderation';

const moderationWorker = {
  start: async () => {
    const channel = getChannel();
    await channel.assertQueue(QUEUE, { durable: true });

    channel.consume(QUEUE, async (msg) => {
      if (msg !== null) {
        try {
          const content = JSON.parse(msg.content.toString());
          console.log('Processing moderation:', content);

          // TODO: Implement moderation logic (e.g., content filtering)

          channel.ack(msg);
        } catch (error) {
          console.error('Moderation worker error:', error);
          channel.nack(msg, false, false);
        }
      }
    });

    console.log('Moderation worker started');
  },
};

module.exports = moderationWorker;
