import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../feed/models/thread_model.dart';
import '../models/create_thread_request.dart';
import '../models/comment_model.dart';

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ThreadRepository(ref.read(dioProvider));
});

class ThreadRepository {
  final Dio _dio;
  ThreadRepository(this._dio);

  Future<void> createThread(CreateThreadRequest request) async {
    await _dio.post('/threads', data: request.toJson());
  }

  // שליפת פוסט בודד
  Future<ThreadModel> getThread(String threadId) async {
    final response = await _dio.get('/threads/$threadId');
    return ThreadModel.fromJson(response.data);
  }

  // פעולת Toggle ללייק (השרת מחזיר { liked: true/false })
  Future<bool> toggleLike(String threadId) async {
    final response = await _dio.post('/threads/$threadId/like');
    return response.data['liked'] ?? false;
  }

  // שליפת תגובות (עם תמיכה בעימוד בסיסי)
  Future<List<CommentModel>> getComments(String threadId, {int page = 1, int limit = 20}) async {
    final response = await _dio.get('/threads/$threadId/comments', queryParameters: {'page': page, 'limit': limit});
    final dataList = response.data as List;
    return dataList.map((json) => CommentModel.fromJson(json)).toList();
  }

  // יצירת תגובה חדשה
  Future<CommentModel> createComment(String threadId, String content) async {
    final response = await _dio.post('/threads/$threadId/comments', data: {'content': content.trim()});
    return CommentModel.fromJson(response.data);
  }
}