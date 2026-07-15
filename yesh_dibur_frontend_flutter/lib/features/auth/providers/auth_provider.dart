import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import '../../../core/local_storage/storage_service.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // מאזינים לשינויי התחברות מ-Firebase
    final firebaseUser = FirebaseAuth.instance.currentUser;
    
    if (firebaseUser != null) {
      // אם יש משתמש ב-Firebase, נמשוך את הפרופיל המלא שלו משרת ה-Node.js שלנו
      return _fetchUserProfile();
    }
    
    // אם אין משתמש, אנחנו במצב אורח (Guest Mode)
    return null;
  }

  Future<UserModel?> _fetchUserProfile() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.getUserProfile();
      return user;
    } catch (e) {
      // אם יש שגיאה במשיכת הפרופיל (למשל השרת למטה), נוכל לטפל בזה כאן
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      // מחיקת טוקנים מהמכשיר לפי חוקי הפרודקשן
      await ref.read(storageServiceProvider).clearAll();
      await ref.read(authRepositoryProvider).signOut();
      
      // מעבר חזרה למצב אורח
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}