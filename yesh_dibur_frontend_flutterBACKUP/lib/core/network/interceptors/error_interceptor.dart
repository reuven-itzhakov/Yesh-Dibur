import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      final data = err.response!.data;

      // שינוי: השרת שלך מחזיר את מערך השגיאות תחת "details" ולא "error"
      if (statusCode == 400 && data != null && data['details'] is List) {
        final errorsList = data['details'] as List;
        final Map<String, String> validationErrors = {};

        for (var errObj in errorsList) {
          if (errObj is Map && errObj.containsKey('path') && errObj.containsKey('message')) {
            final field = errObj['path'].toString();
            validationErrors[field] = errObj['message'].toString();
          }
        }

        if (validationErrors.isNotEmpty) {
          throw ValidationException(validationErrors);
        }
      }

      // טיפול בשגיאות שרת כלליות
      if (data != null && data['error'] is String) {
        throw ServerException(data['error']);
      }
    }

    if (err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.connectionError) {
      throw ServerException('אין חיבור לאינטרנט. אנא בדוק את הרשת שלך ונסה שוב.');
    }

    throw ServerException('אירעה שגיאה לא צפויה מול השרת.');
  }
}