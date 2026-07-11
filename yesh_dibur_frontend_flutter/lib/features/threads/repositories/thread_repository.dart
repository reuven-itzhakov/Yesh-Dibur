import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../models/create_thread_request.dart';

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ThreadRepository(ref.read(dioProvider));
});

class ThreadRepository {
  final Dio _dio;
  ThreadRepository(this._dio);

  Future<void> createThread(CreateThreadRequest request) async {
    await _dio.post('/threads', data: request.toJson());
  }
}