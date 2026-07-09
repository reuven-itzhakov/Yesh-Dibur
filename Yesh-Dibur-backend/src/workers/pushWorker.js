const { getChannel } = require('../config/rabbitmq');
const { messaging } = require('../config/firebase');
const { pool } = require('../config/db'); // חובה להוסיף כדי לשלוף מכשירים ושמות משתמשים

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
          const payload = JSON.parse(msg.content.toString());
          console.log('Processing push notification for chat:', payload.chatId);

          const { receiverId, senderId, chatId, content } = payload;

          // 1. שליפת כל המכשירים הפעילים של מקבל ההודעה
          const { rows: devices } = await pool.query('SELECT fcm_token FROM device_tokens WHERE user_id = $1', [receiverId]);
          
          if (devices.length === 0) {
            console.log(`No active devices found for user ${receiverId}. Discarding message.`);
            channel.ack(msg);
            return;
          }

          const tokens = devices.map(d => d.fcm_token);

          // 2. שליפת שם השולח לתצוגה יפה בהתראה
          const { rows: senderRows } = await pool.query('SELECT name FROM users WHERE id = $1', [senderId]);
          const senderName = senderRows.length > 0 ? senderRows[0].name : 'משתמש';

          // 3. בניית המעטפת של ההתראה (Payload)
          const messagePayload = {
            notification: {
              title: `הודעה חדשה מ-${senderName}`,
              body: content.length > 50 ? content.substring(0, 47) + '...' : content,
            },
            data: {
              type: 'chat',
              chatId: String(chatId),
              senderId: String(senderId)
            },
            // הגדרות קריטיות כדי שההתראה תעבוד כשהאפליקציה סגורה או הטלפון נעול
            android: {
              priority: 'high',
              notification: { sound: 'default' }
            },
            apns: {
              payload: {
                aps: { sound: 'default', contentAvailable: true }
              }
            },
            tokens: tokens
          };

          // 4. שיגור ההודעות לשרתי גוגל
          const response = await messaging.sendEachForMulticast(messagePayload);

          // 5. מנגנון ניקוי חכם (Garbage Collection): מחיקת טוקנים מתים אם המשתמש הסיר את האפליקציה
          if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
              if (!resp.success) {
                const errorCode = resp.error?.code;
                if (errorCode === 'messaging/invalid-registration-token' ||
                    errorCode === 'messaging/registration-token-not-registered') {
                  failedTokens.push(tokens[idx]);
                }
              }
            });

            if (failedTokens.length > 0) {
              await pool.query('DELETE FROM device_tokens WHERE fcm_token = ANY($1)', [failedTokens]);
              console.log(`Cleaned up ${failedTokens.length} dead FCM tokens from database.`);
            }
          }

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