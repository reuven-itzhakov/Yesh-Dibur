import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yesh_dibur_frontend_flutter/features/auth/providers/auth_provider.dart';
import 'onboarding_state.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import '../../../core/errors/exceptions.dart';

// חושף את ה-Notifier למסכי ההרשמה
final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  // פונקציות עדכון לכל שלב במסך ההרשמה
  void updateEmailAndPassword(String email, String password) {
    state = state.copyWith(email: email, password: password, errorMessage: null);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone, errorMessage: null);
  }

  void updateProfileData({DateTime? birthDate, LocationModel? location, String? username}) {
    state = state.copyWith(
      birthDate: birthDate ?? state.birthDate,
      location: location ?? state.location,
      username: username ?? state.username,
      errorMessage: null,
    );
  }

  void updateInterests(List<String> interests) {
    state = state.copyWith(interests: interests, errorMessage: null);
  }

  // הפעולה הסופית שתקרא לנתיב ההרשמה בשרת
Future<bool> submitRegistration() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // וידוא שהמשתמש אכן עבר את אימות הטלפון ב-Firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'שגיאת אימות: משתמש לא מחובר ב-Firebase');
        return false;
      }

      final repository = ref.read(authRepositoryProvider);
      
      // הרכבת האובייקט שיישלח לשרת (הטוקן יתווסף אוטומטית דרך ה-Dio Client)
      final userData = {
        'name': state.username, // תיקון: השרת דורש 'name' ולא 'username'
        'email': state.email,
        'phone': state.phone,
        'birth_date': state.birthDate?.toUtc().toIso8601String(),
        'interests': state.interests,
        if (state.location != null) 'location': {
          'lat': state.location!.lat,
          'lng': state.location!.lng,
        }
      };
      final createdUser = await repository.registerUserToBackend(userData);
      
      // שינוי 2: דוחפים את המשתמש ישירות לסטייט הגלובלי!
      ref.read(authProvider.notifier).setUser(createdUser);
      
      state = state.copyWith(isLoading: false);
      return true; // ההרשמה בשרת הצליחה!
      
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'שגיאה לא צפויה התרחשה: $e');
      return false;
    }
  }
}