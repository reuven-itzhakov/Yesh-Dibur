// tests/pushWorker.test.js
const pushWorker = require('../src/workers/pushWorker');
const { getChannel } = require('../src/config/rabbitmq');
const { pool } = require('../src/config/db');
const { messaging } = require('../src/config/firebase');

// Mocks
jest.mock('../src/config/rabbitmq', () => ({
  getChannel: jest.fn(),
}));

jest.mock('../src/config/db', () => ({
  pool: { query: jest.fn() }
}));

jest.mock('../src/config/firebase', () => ({
  messaging: {
    sendEachForMulticast: jest.fn()
  }
}));

describe('Push Notifications Worker (pushWorker.js)', () => {
  let mockChannel;
  let consumeCallback;

  beforeEach(() => {
    jest.clearAllMocks();

    // יצירת ערוץ (Channel) מזויף של RabbitMQ
    mockChannel = {
      assertQueue: jest.fn(),
      consume: jest.fn((queue, callback) => {
        // שמירת הקולבק של ה-consume כדי שנוכל "לזרוק" אליו הודעות באופן יזום בטסטים
        consumeCallback = callback; 
      }),
      ack: jest.fn(),
      publish: jest.fn(),
    };

    getChannel.mockReturnValue(mockChannel);
  });

  it('should not process if channel is null', async () => {
    getChannel.mockReturnValue(null);
    await pushWorker.start();
    expect(mockChannel.assertQueue).not.toHaveBeenCalled();
  });

  describe('Message Processing', () => {
    beforeEach(async () => {
      await pushWorker.start(); // מפעיל את הוורקר ורושם את ה-consumeCallback
    });

    const mockPayload = {
      type: 'new_message',
      chatId: 'chat-123',
      senderId: 'user-1',
      receiverId: 'user-2',
      content: 'הודעת טסט'
    };

    const mockRabbitMessage = {
      content: Buffer.from(JSON.stringify(mockPayload)),
      properties: { headers: {} }
    };

    it('should discard message and ack if receiver has no active devices', async () => {
      // דימוי מצב שבו המסד מחזיר מערך ריק של מכשירים למקבל ההודעה
      pool.query.mockResolvedValueOnce({ rows: [] });

      await consumeCallback(mockRabbitMessage);

      // ווידוא שהפונקציה חיפשה מכשירים
      expect(pool.query).toHaveBeenCalledWith(
        'SELECT fcm_token FROM device_tokens WHERE user_id = $1', 
        ['user-2']
      );
      // ווידוא שלא נשלח פוש
      expect(messaging.sendEachForMulticast).not.toHaveBeenCalled();
      // ווידוא שההודעה סומנה כטופלה כדי שתצא מהתור
      expect(mockChannel.ack).toHaveBeenCalledWith(mockRabbitMessage);
    });

    it('should send push notification and handle dead tokens successfully', async () => {
      // 1. דימוי שליפת המכשירים של המקבל
      pool.query.mockResolvedValueOnce({ 
        rows: [{ fcm_token: 'token-active' }, { fcm_token: 'token-dead' }] 
      });
      // 2. דימוי שליפת שם השולח
      pool.query.mockResolvedValueOnce({ 
        rows: [{ name: 'ישראל' }] 
      });

      // 3. דימוי התשובה מגוגל (Firebase) - טוקן אחד הצליח ואחד נכשל (נמחק מהטלפון)
      messaging.sendEachForMulticast.mockResolvedValueOnce({
        failureCount: 1,
        responses: [
          { success: true },
          { success: false, error: { code: 'messaging/invalid-registration-token' } }
        ]
      });

      // 4. דימוי השאילתה שמוחקת את הטוקן המת מהמסד
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      await consumeCallback(mockRabbitMessage);

      // ווידוא שהפוש נשלח עם הנתונים הנכונים
      expect(messaging.sendEachForMulticast).toHaveBeenCalledWith(expect.objectContaining({
        notification: {
          title: 'הודעה חדשה מ-ישראל',
          body: 'הודעת טסט'
        },
        tokens: ['token-active', 'token-dead']
      }));

      // ווידוא שמנגנון ניקוי האשפה (Garbage Collection) של טוקנים מתים עבד
      expect(pool.query).toHaveBeenCalledWith(
        'DELETE FROM device_tokens WHERE fcm_token = ANY($1)',
        [['token-dead']]
      );

      // ווידוא אק (אישור) לתור
      expect(mockChannel.ack).toHaveBeenCalledWith(mockRabbitMessage);
    });

    it('should retry message on failure and send to DLQ after max retries', async () => {
      // גרימת שגיאה מלאכותית בשאילתת המסד כדי לדמות קריסה פתאומית
      pool.query.mockRejectedValueOnce(new Error('Database connection lost'));

      // ניסיון ראשון
      await consumeCallback(mockRabbitMessage);

      // ווידוא שההודעה נשלחה חזרה לתור עם header של ניסיון חוזר 1
      expect(mockChannel.publish).toHaveBeenCalledWith('', 'push', mockRabbitMessage.content, {
        headers: { 'x-retries': 1 }
      });
      expect(mockChannel.ack).toHaveBeenCalledWith(mockRabbitMessage);

      // --- סימולציית הגעה ל-Max Retries (מעל 3) ---
      const failedMessage = {
        content: Buffer.from(JSON.stringify(mockPayload)),
        properties: { headers: { 'x-retries': 3 } }
      };

      pool.query.mockRejectedValueOnce(new Error('Database connection lost'));
      
      await consumeCallback(failedMessage);

      // הפעם ההודעה צריכה לעבור ל-DLQ (Dead Letter Queue) כי עברנו את סף הניסיונות
      expect(mockChannel.publish).toHaveBeenCalledWith('', 'push_dlq', failedMessage.content);
      expect(mockChannel.ack).toHaveBeenCalledWith(failedMessage);
    });
  });
});