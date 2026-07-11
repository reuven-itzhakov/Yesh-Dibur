import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/sockets/socket_service.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

final chatMessagesProvider = StateNotifierProvider.autoDispose.family<ChatMessagesNotifier, AsyncValue<List<MessageModel>>, String>((ref, chatId) {
  return ChatMessagesNotifier(ref, chatId);
});

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final Ref ref;
  final String chatId;
  late final SocketService _socketService;

  ChatMessagesNotifier(this.ref, this.chatId) : super(const AsyncValue.loading()) {
    _socketService = ref.read(socketServiceProvider);
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      // 1. שליפת היסטוריית ההודעות מה-REST API
      final messages = await ref.read(chatRepositoryProvider).getChatMessages(chatId);
      if (mounted) state = AsyncValue.data(messages);

      // 2. חיבור לסוקט במידה ולא מחובר, והצטרפות לחדר הספציפי
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }
      _socketService.joinChat(chatId);
      _socketService.markAsRead(chatId); // סימון כנקרא מיד עם הכניסה

      // 3. רישום מאזין לקבלת הודעות חדשות מהצד השני
      _socketService.on('newMessage', _onNewMessage);
      
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _onNewMessage(dynamic data) {
    if (!mounted) return;
    
    // השרת שלך מחזיר את אובייקט ההודעה השלם כפי שנשמר במסד הנתונים
    final newMessage = MessageModel.fromJson(data);
    final currentMessages = state.value ?? [];
    
    // מוסיפים את ההודעה לראש הרשימה (אינדקס 0) מכיוון שה-ListView שלנו יהיה הפוך
    state = AsyncValue.data([newMessage, ...currentMessages]);
    
    // עדכון השרת שקראנו את ההודעה
    _socketService.markAsRead(chatId);
  }

  Future<bool> sendMessage(String content, String receiverId) async {
    if (content.trim().isEmpty) return false;
    
    try {
      // שליחה עם Callback (ACK) מהשרת
      final response = await _socketService.sendMessage({
        'chatId': chatId,
        'receiverId': receiverId,
        'content': content.trim(),
      });

      if (response['status'] == 'ok') {
        final newMessage = MessageModel.fromJson(response['data']);
        final currentMessages = state.value ?? [];
        if (mounted) state = AsyncValue.data([newMessage, ...currentMessages]);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void notifyTyping() {
    _socketService.emitTyping(chatId);
  }

  @override
  void dispose() {
    // ניקוי המאזינים ועזיבת החדר כשהמשתמש סוגר את חלון הצ'אט
    _socketService.off('newMessage');
    _socketService.leaveChat(chatId);
    super.dispose();
  }
}