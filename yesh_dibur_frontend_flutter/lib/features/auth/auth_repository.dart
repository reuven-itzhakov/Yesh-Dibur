import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  AuthRepository(this._firebaseAuth, this._dio);

  // פונקציה לדוגמה: הרשמה מלאה של משתמש חדש
  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String birthDate,
    required List<String> interests,
  }) async {
    try {
      // 1. יצירת המשתמש ב-Firebase לקבלת הגנת JWT
      UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. שליפת הטוקן הטרי כדי להוכיח לשרת שלנו שאנחנו מאומתים
      String? token = await credential.user?.getIdToken();

      // 3. שליחת המידע לשרת ה-Node.js כדי לשמור במסד הנתונים (PostgreSQL)
      // שימו לב שהשדות תואמים בדיוק לסכמת ה-Zod שהגדרנו בשרת
      await _dio.post(
        '/api/v1/users/register',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'birth_date': birthDate,
          'interests': interests,
        },
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('שגיאת התחברות: ${e.message}');
    } on DioException catch (e) {
      // כאן נוכל לתפוס את שגיאות ה-Zod שהשרת מחזיר בסטטוס 400
      throw Exception('שגיאת שרת: ${e.response?.data['error'] ?? e.message}');
    }
  }
}