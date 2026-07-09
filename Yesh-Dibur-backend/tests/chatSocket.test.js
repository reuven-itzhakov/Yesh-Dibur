// tests/chatSocket.test.js
const chatSocket = require('../src/sockets/chatSocket');
const chatService = require('../src/services/chatService');
const { getChannel } = require('../src/config/rabbitmq');

// Mocks
jest.mock('../src/services/chatService');
jest.mock('../src/config/rabbitmq');

describe('Chat Socket Handlers (chatSocket.js)', () => {
  let mockIo;
  let mockSocket;
  let mockEmit;
  let socketHandlers;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // אובייקט Emit מזויף כדי שנוכל לבדוק האם השרת שידר הודעה ללקוחות אחרים
    mockEmit = jest.fn();

    // בניית אובייקט סוקט מזויף
    mockSocket = {
      id: 'socket-id-123',
      user: { uid: 'firebase-uid-1' }, // המשתמש שכביכול התחבר
      join: jest.fn(),
      leave: jest.fn(),
      to: jest.fn().mockReturnValue({ emit: mockEmit }), // שרשור פונקציות: socket.to(room).emit(event)
      on: jest.fn(), // פונקציית ההאזנה לאירועים
    };

    mockIo = {
      // אם תרצה להשתמש ב-io במקומות מסוימים (כרגע הפונקציה מקבלת אותו אבל משתמשת בעיקר ב-socket)
    };

    // משתנה שישמור את כל הפונקציות שהסוקט מאזין להן, כדי שנוכל להפעיל אותן בטסטים
    socketHandlers = {};
    
    // דריסת הפונקציה socket.on כדי שנשמור את ה-Callback של כל אירוע
    mockSocket.on.mockImplementation((eventName, callback) => {
      socketHandlers[eventName] = callback;
    });

    // הפעלת הפונקציה שרושמת את כל האירועים על הסוקט שלנו
    chatSocket(mockIo, mockSocket);
  });

  describe('joinChat & leaveChat', () => {
    it('should join the chat room if user is a verified participant', async () => {
      chatService.verifyParticipant.mockResolvedValueOnce(true); // הדמיה שהמשתמש מורשה
      
      const chatId = 'chat-123';
      await socketHandlers['joinChat'](chatId); // הפעלת האירוע באופן ידני

      expect(chatService.verifyParticipant).toHaveBeenCalledWith(chatId, 'firebase-uid-1');
      expect(mockSocket.join).toHaveBeenCalledWith('chat:chat-123');
    });

    it('should NOT join the chat room if user is NOT a participant', async () => {
      chatService.verifyParticipant.mockResolvedValueOnce(false); // הדמיה שהמשתמש נחסם או לא שייך
      
      const chatId = 'chat-123';
      await socketHandlers['joinChat'](chatId);

      expect(mockSocket.join).not.toHaveBeenCalled();
    });

    it('should leave the chat room', () => {
      const chatId = 'chat-123';
      socketHandlers['leaveChat'](chatId);
      expect(mockSocket.leave).toHaveBeenCalledWith('chat:chat-123');
    });
  });

  describe('sendMessage', () => {
    const mockCallback = jest.fn(); // פונקציית האישור של הלקוח (Ack Callback)
    const mockRabbitChannel = { publish: jest.fn() };

    beforeEach(() => {
      getChannel.mockReturnValue(mockRabbitChannel);
    });

    it('should return error via callback if content and image are empty', async () => {
      await socketHandlers['sendMessage']({
        chatId: 'chat-123',
        receiverId: 'user-2',
        content: '   ', // תוכן ריק (רווחים)
      }, mockCallback);

      expect(mockCallback).toHaveBeenCalledWith({
        status: 'error',
        error: 'Message must contain valid text or an image'
      });
      expect(chatService.saveMessage).not.toHaveBeenCalled();
    });

    it('should save message, emit to room, and publish push notification', async () => {
      const savedMessage = { id: 'msg-1', content: 'שלום' };
      chatService.saveMessage.mockResolvedValueOnce(savedMessage);

      await socketHandlers['sendMessage']({
        chatId: 'chat-123',
        receiverId: 'user-2',
        content: 'שלום',
      }, mockCallback);

      // 1. ווידוא שמירת ההודעה במסד
      expect(chatService.saveMessage).toHaveBeenCalledWith(
        'firebase-uid-1', 'user-2', 'chat-123', 'שלום', null, null
      );

      // 2. ווידוא שההודעה שודרה לשאר המשתמשים בחדר הצ'אט
      expect(mockSocket.to).toHaveBeenCalledWith('chat:chat-123');
      expect(mockEmit).toHaveBeenCalledWith('newMessage', savedMessage);

      // 3. ווידוא שנשלחה התראת Push לתור ה-RabbitMQ
      expect(mockRabbitChannel.publish).toHaveBeenCalledWith(
        '',
        'push',
        expect.any(Buffer) // וידוא שנשלח באפר תקין לתור
      );

      // 4. ווידוא שהשולח קיבל אישור חיובי
      expect(mockCallback).toHaveBeenCalledWith({
        status: 'ok',
        data: savedMessage
      });
    });
  });

  describe('typing and markAsRead', () => {
    it('should emit typing event only if user is participant', async () => {
      chatService.verifyParticipant.mockResolvedValueOnce(true);

      await socketHandlers['typing']({ chatId: 'chat-123' });

      expect(mockSocket.to).toHaveBeenCalledWith('chat:chat-123');
      expect(mockEmit).toHaveBeenCalledWith('userTyping', {
        userId: 'firebase-uid-1',
        chatId: 'chat-123'
      });
    });

    it('should update DB and emit messagesRead event', async () => {
      await socketHandlers['markAsRead']({ chatId: 'chat-123' });

      // ווידוא עדכון המסד מאחורי הקלעים
      expect(chatService.markMessagesAsRead).toHaveBeenCalledWith('chat-123', 'firebase-uid-1');
      
      // ווידוא שידור הוי הכחול לשולח
      expect(mockSocket.to).toHaveBeenCalledWith('chat:chat-123');
      expect(mockEmit).toHaveBeenCalledWith('messagesRead', {
        chatId: 'chat-123',
        readBy: 'firebase-uid-1'
      });
    });
  });
});