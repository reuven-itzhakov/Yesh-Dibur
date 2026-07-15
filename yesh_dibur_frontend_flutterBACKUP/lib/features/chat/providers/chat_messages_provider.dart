import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/sockets/socket_service.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

part 'chat_messages_provider.g.dart';

@riverpod
class ChatMessages extends _$ChatMessages {
  late final SocketService _socketService;

  @override
  FutureOr<List<MessageModel>> build(String chatId) async {
    _socketService = ref.read(socketServiceProvider);

    // 1. שליפת היסטוריית ההודעות מה-REST API
    final messages = await ref.read(chatRepositoryProvider).getChatMessages(chatId);

    // 2. חיבור לסוקט
    if (!_socketService.isConnected) {
      await _socketService.connect();
    }
    _socketService.joinChat(chatId);
    _socketService.markAsRead(chatId);
    _socketService.on('newMessage', _onNewMessage);

    // 3. ניקוי בעת יציאה מהמסך (במקום מתודת dispose הישנה)
    ref.onDispose(() {
      _socketService.off('newMessage');
      _socketService.leaveChat(chatId);
    });

    return messages;
  }

  void _onNewMessage(dynamic data) {
    final newMessage = MessageModel.fromJson(data);
    final currentMessages = state.value ?? [];
    state = AsyncValue.data([newMessage, ...currentMessages]);
    _socketService.markAsRead(chatId);
  }

  Future<bool> sendMessage(String content, String receiverId) async {
    if (content.trim().isEmpty) return false;

    try {
      final response = await _socketService.sendMessage({
        'chatId': chatId,
        'receiverId': receiverId,
        'content': content.trim(),
      });

      if (response['status'] == 'ok') {
        final newMessage = MessageModel.fromJson(response['data']);
        final currentMessages = state.value ?? [];
        state = AsyncValue.data([newMessage, ...currentMessages]);
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
}