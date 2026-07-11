import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/chat_conversation_model.dart';
import '../repositories/chat_repository.dart';

// שימוש ב-StateNotifierProvider שעוקף את בעיית הטיפוסים
final chatInboxProvider = StateNotifierProvider.autoDispose<ChatInboxNotifier, AsyncValue<List<ChatConversationModel>>>((ref) {
  return ChatInboxNotifier(ref);
});

class ChatInboxNotifier extends StateNotifier<AsyncValue<List<ChatConversationModel>>> {
  final Ref ref;

  // אתחול המצב לטעינה ושליפת השיחות באופן מיידי
  ChatInboxNotifier(this.ref) : super(const AsyncValue.loading()) {
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    try {
      final chats = await ref.read(chatRepositoryProvider).getChats();
      if (mounted) state = AsyncValue.data(chats);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final chats = await ref.read(chatRepositoryProvider).getChats();
      if (mounted) state = AsyncValue.data(chats);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}