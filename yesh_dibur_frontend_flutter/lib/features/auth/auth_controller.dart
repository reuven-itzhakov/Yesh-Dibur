import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'auth_repository.dart';

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthInitial());

  // שימוש בפרמטרים מפורשים במקום Map כדי למנוע שגיאות הקלדה בזמן ריצה
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String birthDate,
    required List<String> interests,
  }) async {
    state = AuthLoading(); 
    try {
      await _repository.registerUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
        birthDate: birthDate,
        interests: interests,
      );
      state = AuthSuccess(); 
    } catch (e) {
      state = AuthError(e.toString()); 
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = AuthRepository(FirebaseAuth.instance, Dio(BaseOptions(baseUrl: 'https://your-api.com')));
  return AuthController(repository);
});