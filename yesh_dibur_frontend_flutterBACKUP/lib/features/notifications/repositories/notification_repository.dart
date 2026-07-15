import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(dioProvider));
});

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/notifications', queryParameters: {'page': page, 'limit': limit});
    final data = response.data as List;
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.put('/notifications/read-all');
  }
}