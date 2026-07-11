import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../models/register_request.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<void> registerUserOnBackend(RegisterRequest request) async {
    // השגיאות נתפסות ומפוענחות ב-ErrorInterceptor
    await _dio.post('/users/register', data: request.toJson());
  }
  
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; 
      }
      rethrow;
    }
  }
}