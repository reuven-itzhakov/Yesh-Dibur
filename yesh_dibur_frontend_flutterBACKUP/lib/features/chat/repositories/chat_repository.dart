import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../models/chat_conversation_model.dart';
import '../models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(dioProvider));
});

class ChatRepository {
  final Dio _dio;
  ChatRepository(this._dio);

  // שליפת תיבת השיחות (Inbox)
  Future<List<ChatConversationModel>> getChats({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/chats', queryParameters: {'page': page, 'limit': limit});
    final data = response.data as List;
    return data.map((json) => ChatConversationModel.fromJson(json)).toList();
  }

  // שליפת היסטוריית ההודעות לשיחה ספציפית
  Future<List<MessageModel>> getChatMessages(String chatId, {int page = 1, int limit = 20}) async {
    final response = await _dio.get('/chats/$chatId/messages', queryParameters: {'page': page, 'limit': limit});
    final data = response.data as List;
    // הופכים את הרשימה כדי שההודעות החדשות יופיעו למטה
    return data.map((json) => MessageModel.fromJson(json)).toList().reversed.toList();
  }

  // יצירת שיחה חדשה
  Future<ChatConversationModel> createChat(String receiverId) async {
    final response = await _dio.post('/chats', data: {'receiver_id': receiverId});
    return ChatConversationModel.fromJson(response.data);
  }
}