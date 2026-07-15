import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';

// חושף את לקוח ה-Dio לכלל האפליקציה דרך Riverpod
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // TODO: בהמשך נשלוף כאן את הטוקן האמיתי מ-Firebase Auth
        // final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        // if (token != null) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }
        
        return handler.next(options); // ממשיך את הבקשה
      },
      onError: (DioException e, handler) {
        // מקום מרכזי לטיפול בשגיאות רוחביות
        // למשל: אם חוזרת שגיאת 401 (לא מורשה), נפעיל כאן לוגיקת התנתקות
        return handler.next(e);
      },
    ),
  );

  return dio;
});