import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/exceptions.dart';
import '../models/register_request.dart';
import '../repositories/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> registerUser({
    required String password,
    required RegisterRequest request,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. יצירת המשתמש ב-Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: request.email.trim(),
        password: password.trim(),
      );

      // 2. שליחת הנתונים לשרת
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.registerUserOnBackend(request);

      state = const AsyncValue.data(null);
      return true;

    } on FirebaseAuthException catch (e) {
      String errorMsg = 'שגיאת הרשמה ב-Firebase.';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'האימייל הזה כבר קיים במערכת.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'הסיסמה חלשה מדי.';
      }
      state = AsyncValue.error(ServerException(errorMsg), StackTrace.current);
      return false;
    } on ValidationException catch (e) {
      // וולידציות Zod
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(ServerException(e.toString()), st);
      return false;
    }
  }
}