import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../models/thread_model.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.read(dioProvider));
});

// מחלקה פשוטה שעוזרת לנו להחזיר גם את רשימת הפוסטים וגם את הסמן (Cursor) לעמוד הבא
class FeedResponse {
  final List<ThreadModel> threads;
  final String? nextCursor;

  FeedResponse({required this.threads, this.nextCursor});
}

class FeedRepository {
  final Dio _dio;

  FeedRepository(this._dio);

  Future<FeedResponse> getDiscoveryFeed({String? cursor, int limit = 20}) async {
    final response = await _dio.get(
      '/feeds/discovery',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    final data = response.data['data'] as List;
    final nextCursor = response.data['next_cursor'] as String?;

    return FeedResponse(
      threads: data.map((json) => ThreadModel.fromJson(json)).toList(),
      nextCursor: nextCursor,
    );
  }

  Future<FeedResponse> getMyGroupsFeed({String? cursor, int limit = 20}) async {
    final response = await _dio.get(
      '/feeds/my-groups',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    final data = response.data['data'] as List;
    final nextCursor = response.data['next_cursor'] as String?;

    return FeedResponse(
      threads: data.map((json) => ThreadModel.fromJson(json)).toList(),
      nextCursor: nextCursor,
    );
  }
}