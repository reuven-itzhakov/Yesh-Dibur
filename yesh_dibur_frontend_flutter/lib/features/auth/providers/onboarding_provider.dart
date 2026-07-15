import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final repository = ref.read(authRepositoryProvider);
      
      // הרכבת האובייקט שיישלח לשרת
      final userData = {
        'email': state.email,
        'phone': state.phone,
        'username': state.username,
        'birth_date': state.birthDate?.toIso8601String(),
        'interests': state.interests,
        if (state.location != null) 'location': {
          'lat': state.location!.lat,
          'lng': state.location!.lng,
        }
      };

      // TODO: הוספת יצירת משתמש ב-Firebase לפני הפנייה לשרת (נשלים כשנגיע ללוגיקת ה-OTP)
      
      await repository.registerUserToBackend(userData);
      
      state = state.copyWith(isLoading: false);
      return true; // ההרשמה הצליחה
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'שגיאה לא צפויה התרחשה');
      return false;
    }
  }
}