import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/registration_state.dart';
// כאן תצטרך לייבא את ה-AuthRepository שלך שבו נוסיף בהמשך פונקציות לבדיקת ייחודיות

part 'registration_wizard_controller.g.dart';

@riverpod
class RegistrationWizardController extends _$RegistrationWizardController {
  @override
  RegistrationState build() {
    return RegistrationState();
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1, errorMessage: null);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, errorMessage: null);
    }
  }

  void updateData(RegistrationState newData) {
    state = newData.copyWith(errorMessage: null);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  // שלב אימות אימייל (מומלץ לבדוק מול השרת שאינו קיים)
  Future<void> validateEmailAndProceed(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // כאן תהיה קריאה לשרת: await authRepository.checkEmailUnique(email);
      state = state.copyWith(email: email, currentStep: state.currentStep + 1, isLoading: false);
    } catch (e) {
      setError('האימייל כבר קיים במערכת');
    }
  }

  // שלחת קוד OTP לטלפון
  // שלחת קוד OTP לטלפון
  Future<void> sendOtpAndProceed(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // 1. ניקוי רווחים או מקפים אם המשתמש הקליד בטעות
      String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      
      // 2. המרה לפורמט E.164
      String formattedPhone = cleanPhone;
      if (cleanPhone.startsWith('05')) {
        formattedPhone = '+972${cleanPhone.substring(1)}';
      } else if (!cleanPhone.startsWith('+')) {
        formattedPhone = '+$cleanPhone';
      }

      // כאן תהיה קריאה לשרת לוודא שהטלפון לא בשימוש
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone, // משתמשים במספר המפורמט
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          setError('שגיאה בשליחת הקוד: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            phone: formattedPhone, // שומרים את המספר המפורמט בסטייט
            verificationId: verificationId, 
            currentStep: state.currentStep + 1, 
            isLoading: false
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setError('מספר הטלפון כבר קיים במערכת או שגוי');
    }
  }

  // אימות קוד ה-OTP
  Future<void> verifyOtpAndProceed(String smsCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId,
        smsCode: smsCode,
      );
      // מקשרים את הטלפון לחשבון (או מאמתים אותו כחלק מתהליך הרישום)
      // הערה: נשתמש בזה כאימות בלבד בשלב זה, היצירה הסופית תהיה עם אימייל וסיסמה
      state = state.copyWith(currentStep: state.currentStep + 1, isLoading: false);
    } catch (e) {
      setError('קוד שגוי, אנא נסה שוב');
    }
  }

  // שלב בחירת שם משתמש (בדיקת כפילות)
  Future<void> validateUsernameAndProceed(String username) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // קריאה לשרת: await authRepository.checkUsernameUnique(username);
      state = state.copyWith(username: username, currentStep: state.currentStep + 1, isLoading: false);
    } catch (e) {
      setError('שם המשתמש כבר תפוס');
    }
  }

  // איתור מיקום אוטומטי
  Future<void> detectLocationAndProceed() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('שירותי מיקום כבויים');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('אין הרשאת מיקום');
      }

      Position position = await Geolocator.getCurrentPosition();
      
      state = state.copyWith(
        lat: position.latitude, 
        lng: position.longitude,
        cityName: 'מיקום זוהה אוטומטית', // בפרודקשן כדאי להשתמש ב-geocoding כדי להביא שם עיר אמיתי
        currentStep: state.currentStep + 1,
        isLoading: false
      );
    } catch (e) {
      setError('לא הצלחנו לאתר מיקום: $e');
    }
  }

  // סיום והרשמה סופית
  Future<bool> finishRegistration() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. יצירת המשתמש ב-Firebase עם אימייל וסיסמה
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: state.email, 
        password: state.password
      );

      // 2. העלאת תמונת הפרופיל (אם קיימת) לנתיב בשרת/פיירבייס שרת שלך

      // 3. קריאה ל-Backend שלך ליצירת המשתמש במסד הנתונים עם כל הנתונים
      /*
      await authRepository.registerUserOnBackend(RegisterRequest(
         email: state.email,
         phone: state.phone,
         username: state.username,
         birthDate: state.birthDate!.toUtc().toIso8601String(),
         interests: state.interests,
         location: { 'lat': state.lat, 'lng': state.lng },
         // ...
      ));
      */

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      setError('שגיאה ביצירת החשבון: $e');
      return false;
    }
  }
}