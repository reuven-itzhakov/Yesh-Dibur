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
    // התיקון הקריטי: אנחנו אומרים לאפליקציה "תעצרי הכל ותחכי לפעימה 
    // הראשונה של פיירבייס, כדי שנספיק לקרוא את הזיכרון של המכשיר".
    final firebaseUser = await FirebaseAuth.instance.authStateChanges().first;
    
    if (firebaseUser != null) {
      // פיירבייס זוכר אותך! עכשיו נמשוך את הנתונים הנוספים מהשרת.
      final userProfile = await _fetchUserProfile();
      
      // אם למרות שפיירבייס זוכר אותך אין לנו פרופיל, הבעיה בשרת.
      if (userProfile == null) {
        print('פיירבייס זיהה את המשתמש, אבל משיכת הפרופיל מהשרת נכשלה.');
      }
      
      return userProfile;
    }
    
    // אם פיירבייס החזיר null בפירוש, אתה באמת אורח
    return null;
  }

  void setUser(UserModel user) {
    state = AsyncData(user);
  }

  Future<UserModel?> _fetchUserProfile() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.getUserProfile();
      return user;
    } catch (e) {
      // כאן אנחנו מדפיסים שגיאה צועקת לקונסולה.
      // אם תראה את זה כשתפעיל את האפליקציה, סימן שהבעיה בנתיב ה-GET בשרת שלך.
      print('🚨 שגיאה מול השרת בעת הפעלה מחדש: $e');
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