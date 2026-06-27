const { getChannel } = require('../config/rabbitmq');

const QUEUE = 'moderation';
const DLQ = 'moderation_dlq';
const MAX_RETRIES = 3;

const moderationWorker = {
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
          console.log('Processing moderation for content:', content);

          // TODO: Implement moderation logic (content filtering) using gemini-3.1-pro
          // אם המודל יחזיר שגיאת רשת (למשל Timeout), זה יזרוק Exception ל-catch

          channel.ack(msg);
        } catch (error) {
          console.error('Moderation worker error:', error.message);
          
          const headers = msg.properties.headers || {};
          const retryCount = (headers['x-retries'] || 0) + 1;

          if (retryCount <= MAX_RETRIES) {
            console.log(`Retrying moderation logic, attempt ${retryCount} of ${MAX_RETRIES}`);
            
            channel.publish('', QUEUE, msg.content, {
              headers: { ...headers, 'x-retries': retryCount }
            });
          } else {
            console.log('Max retries reached. Moving content to DLQ for manual review.');
            channel.publish('', DLQ, msg.content);
          }
          
          channel.ack(msg);
        }
      }
    });

    console.log('Moderation worker started and listening for content to filter');
  },
};

module.exports = moderationWorker;