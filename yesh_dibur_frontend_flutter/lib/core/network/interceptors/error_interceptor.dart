import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      final data = err.response!.data;

      // טיפול בשגיאות הוולידציה של Zod (מחזיר מערך תחת המפתח 'error')
      if (statusCode == 400 && data != null && data['error'] is List) {
        final errorsList = data['error'] as List;
        final Map<String, String> validationErrors = {};

        for (var errObj in errorsList) {
          if (errObj is Map && errObj.containsKey('path') && errObj.containsKey('message')) {
            final pathList = errObj['path'] as List;
            // חילוץ שם השדה עליו נפלה הוולידציה
            final field = pathList.isNotEmpty ? pathList.first.toString() : 'general';
            validationErrors[field] = errObj['message'].toString();
          }
        }

        if (validationErrors.isNotEmpty) {
          throw ValidationException(validationErrors);
        }
      }

      // טיפול בשגיאות שרת כלליות (למשל Conflict 409 או שגיאת טוקן 401)
      if (data != null && data['error'] is String) {
        throw ServerException(data['error']);
      }
    }

    // אם זו שגיאת רשת פשוטה (כמו אין אינטרנט)
    if (err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.connectionError) {
      throw ServerException('אין חיבור לאינטרנט. אנא בדוק את הרשת שלך ונסה שוב.');
    }

    throw ServerException('אירעה שגיאה לא צפויה מול השרת.');
  }
}