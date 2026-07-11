const { getChannel } = require('../config/rabbitmq');
const { pool } = require('../config/db'); // חיוני כדי לעדכן את הפוסט לאחר ההחלטה
const { GoogleGenAI } = require('@google/genai');

// יצירת מופע של ה-SDK החדש (חובה להוסיף את המפתח לקובץ ה-.env)
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

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
          const payload = JSON.parse(msg.content.toString());
          console.log(`Processing moderation for thread ID: ${payload.threadId}`);

          const { threadId, content } = payload;

          if (!threadId || !content) {
            console.error('Invalid payload: Missing threadId or content. Discarding message.');
            channel.ack(msg);
            return;
          }

          const prompt = `
            Analyze the following user-generated text for any inappropriate content, hate speech, bullying, explicit language, or severe spam.
            Text to analyze: "${content}"
            
            Respond STRICTLY with a valid JSON object in the exact following format:
            {"status": "approved" | "rejected", "reason": "A short explanation of your decision"}
          `;

          // 1. קריאה למודל הבינה המלאכותית באמצעות ה-SDK החדש עם הנחיה מחמירה לפורמט JSON
          const response = await ai.models.generateContent({
            model: 'models/gemini-3.5-flash',
            contents: prompt,
            config: {
              responseMimeType: 'application/json',
            }
          });

          const responseText = response.text;
          
          // 2. ניקוי בטיחותי (למקרה שהמודל עטף את התשובה בסימוני markdown כמו ```json)
          const cleanJsonString = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
          const decision = JSON.parse(cleanJsonString);

          // 3. עדכון מסד הנתונים בהתאם להחלטת הבינה המלאכותית
          const newStatus = decision.status === 'rejected' ? 'rejected' : 'approved';
          const updateQuery = 'UPDATE threads SET moderation_status = $1 WHERE id = $2';
          await pool.query(updateQuery, [newStatus, threadId]);

          console.log(`Thread ${threadId} moderation complete. Status: ${newStatus}. Reason: ${decision.reason}`);

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