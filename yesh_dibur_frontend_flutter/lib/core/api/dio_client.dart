import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';

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

  // ה-Interceptor שמוודא שאף קריאה לא יוצאת בלי טוקן אבטחה
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // שולפים את המשתמש המחובר הנוכחי מ-Firebase
        final user = FirebaseAuth.instance.currentUser;
        
        if (user != null) {
          // מבקשים טוקן עדכני (מחדש אותו אוטומטית אם פג תוקפו)
          final token = await user.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ),
  );

  return dio;
});