import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_provider.dart';
import '../models/register_request.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  // מזריקים גם את Dio וגם את המופע של Firebase
  return AuthRepository(ref.read(dioProvider), FirebaseAuth.instance);
}

class AuthRepository {
  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._dio, this._firebaseAuth);

  // הפונקציה החדשה להתחברות
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  // הפונקציות הקיימות שלך
  Future<void> registerUserOnBackend(RegisterRequest request) async {
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

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}