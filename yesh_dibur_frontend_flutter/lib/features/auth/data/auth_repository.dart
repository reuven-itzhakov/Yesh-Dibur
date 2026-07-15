import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/user_model.dart';

// הזרקת ה-Repository כדי שנוכל להשתמש בו ב-Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio: dio, firebaseAuth: FirebaseAuth.instance);
});

class AuthRepository {
  final Dio dio;
  final FirebaseAuth firebaseAuth;

  AuthRepository({required this.dio, required this.firebaseAuth});

  // קריאה לנתיב הרישום בשרת שלנו (Node.js)
  Future<UserModel> registerUserToBackend(Map<String, dynamic> userData) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: userData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'שגיאה ביצירת המשתמש', 
          statusCode: response.statusCode
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'שגיאת תקשורת מול השרת',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'שגיאה לא צפויה: $e');
    }
  }

  // שליפת פרופיל המשתמש מהשרת בעת התחברות
  Future<UserModel> getUserProfile() async {
    try {
      final response = await dio.get(ApiConstants.profile);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'לא ניתן למשוך את נתוני הפרופיל',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // התנתקות
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }
  
  // (פונקציות נוספות כמו שליחת OTP דרך Firebase נוסיף בהתאם לצורך בשלבי ה-UI)
}