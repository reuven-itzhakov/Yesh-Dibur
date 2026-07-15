import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/exceptions.dart';
import '../models/register_request.dart';
import '../repositories/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  // הפונקציה החדשה שמבצעת התחברות ומנהלת את הסטטוס (טעינה/שגיאה)
  Future<bool> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return false;
    
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).loginWithEmail(email.trim(), password.trim());
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'שגיאת התחברות.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMsg = 'אימייל או סיסמה שגויים.';
      }
      state = AsyncValue.error(ServerException(errorMsg), StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(ServerException(e.toString()), st);
      return false;
    }
  }

  // הפונקציה הקיימת שלך, מותאמת לגנרטור
  Future<bool> registerUser({
    required String password,
    required RegisterRequest request,
  }) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: request.email.trim(),
        password: password.trim(),
      );

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
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(ServerException(e.toString()), st);
      return false;
    }
  }
}