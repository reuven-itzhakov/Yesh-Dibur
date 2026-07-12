// tests/moderationWorker.test.js

// 1. Mocks לתשתיות הליבה
jest.mock('../src/config/rabbitmq', () => ({
  getChannel: jest.fn(),
}));

jest.mock('../src/config/db', () => ({
  pool: { query: jest.fn() }
}));

// 2. Mock מתקדם לספרייה של Google Gemini שפותר את בעיית ה-Hoisting של Jest
jest.mock('@google/genai', () => {
  const mockGenerate = jest.fn(); // יצירת הפונקציה בתוך הסקופ הסגור
  
  return {
    GoogleGenAI: jest.fn().mockImplementation(() => ({
      getGenerativeModel: jest.fn().mockReturnValue({
        generateContent: mockGenerate
      })
    })),
    // חשיפת הפונקציה החוצה כדי שנוכל לשלוט בה ולבדוק אותה בטסטים
    mockGenerateContent: mockGenerate 
  };
});

// ייבוא הקבצים: חשוב לייבא אותם רק *אחרי* שה-Mocks הוגדרו למעלה!
const moderationWorker = require('../src/workers/moderationWorker');
const { getChannel } = require('../src/config/rabbitmq');
const { pool } = require('../src/config/db');
const { mockGenerateContent } = require('@google/genai');

describe('AI Moderation Worker (moderationWorker.js)', () => {
  let mockChannel;
  let consumeCallback;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.GEMINI_API_KEY = 'test-api-key';

    mockChannel = {
      assertQueue: jest.fn(),
      consume: jest.fn((queue, callback) => {
        consumeCallback = callback; 
      }),
      ack: jest.fn(),
      publish: jest.fn(),
    };

    getChannel.mockReturnValue(mockChannel);
  });

  it('should not process if channel is null', async () => {
    getChannel.mockReturnValue(null);
    await moderationWorker.start();
    expect(mockChannel.assertQueue).not.toHaveBeenCalled();
  });

  describe('Message Processing', () => {
    beforeEach(async () => {
      await moderationWorker.start();
    });

    const validPayload = {
      threadId: 'thread-123',
      content: 'זה פוסט רגיל לחלוטין'
    };

    const validMessage = {
      content: Buffer.from(JSON.stringify(validPayload)),
      properties: { headers: {} }
    };

    it('should discard message and ack if threadId or content is missing', async () => {
      const invalidMessage = {
        content: Buffer.from(JSON.stringify({ threadId: 'thread-123' })), // חסר תוכן
        properties: { headers: {} }
      };

      await consumeCallback(invalidMessage);

      // מוודא שה-API של גוגל לא הופעל
      expect(mockGenerateContent).not.toHaveBeenCalled();
      // מוודא שההודעה נזרקה מהתור
      expect(mockChannel.ack).toHaveBeenCalledWith(invalidMessage);
    });

    it('should approve content and update DB successfully', async () => {
      // דימוי תשובה חיובית מ-Gemini
      mockGenerateContent.mockResolvedValueOnce({
        response: {
          text: () => '{"status": "approved"}'
        }
      });
      pool.query.mockResolvedValueOnce({ rowCount: 1 }); // דימוי עדכון מוצלח במסד

      await consumeCallback(validMessage);

      // ווידוא שהמודל נקרא
      expect(mockGenerateContent).toHaveBeenCalled();
      
      // ווידוא שמסד הנתונים עודכן לסטטוס approved
      expect(pool.query).toHaveBeenCalledWith(
        'UPDATE threads SET moderation_status = $1 WHERE id = $2',
        ['approved', 'thread-123']
      );

      // אישור ההודעה מהתור
      expect(mockChannel.ack).toHaveBeenCalledWith(validMessage);
    });

    it('should reject inappropriate content and update DB', async () => {
      // דימוי תשובה שלילית מ-Gemini
      mockGenerateContent.mockResolvedValueOnce({
        response: {
          text: () => '{"status": "rejected", "reason": "Contains hate speech"}'
        }
      });
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      await consumeCallback(validMessage);
      
      // ווידוא שמסד הנתונים עודכן לסטטוס rejected
      expect(pool.query).toHaveBeenCalledWith(
        'UPDATE threads SET moderation_status = $1 WHERE id = $2',
        ['rejected', 'thread-123']
      );
      expect(mockChannel.ack).toHaveBeenCalledWith(validMessage);
    });

    it('should retry on API failure and move to DLQ after max retries', async () => {
      // דימוי מצב שה-API של גוגל קורס (למשל שגיאת רשת)
      mockGenerateContent.mockRejectedValueOnce(new Error('Google API Timeout'));

      // ניסיון ראשון
      await consumeCallback(validMessage);

      // מוודא שנשלח חזרה לתור הראשי עם מונה ניסיונות
      expect(mockChannel.publish).toHaveBeenCalledWith('', 'moderation', validMessage.content, {
        headers: { 'x-retries': 1 }
      });
      expect(mockChannel.ack).toHaveBeenCalledWith(validMessage);

      // --- סימולציית ניסיון מעל המקסימום המותר ---
      const maxRetriesMessage = {
        content: Buffer.from(JSON.stringify(validPayload)),
        properties: { headers: { 'x-retries': 3 } }
      };

      mockGenerateContent.mockRejectedValueOnce(new Error('Google API Timeout'));
      
      await consumeCallback(maxRetriesMessage);

      // מוודא שהפעם התוכן נזרק לתור הידני (DLQ) לבדיקה של מנהל אנושי
      expect(mockChannel.publish).toHaveBeenCalledWith('', 'moderation_dlq', maxRetriesMessage.content);
      expect(mockChannel.ack).toHaveBeenCalledWith(maxRetriesMessage);
    });
  });
});