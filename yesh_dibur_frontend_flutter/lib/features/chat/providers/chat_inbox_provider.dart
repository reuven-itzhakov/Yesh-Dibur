import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chat_conversation_model.dart';
import '../repositories/chat_repository.dart';

part 'chat_inbox_provider.g.dart';

@riverpod
class ChatInbox extends _$ChatInbox {
  @override
  FutureOr<List<ChatConversationModel>> build() async {
    return ref.read(chatRepositoryProvider).getChats();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(chatRepositoryProvider).getChats());
  }
}