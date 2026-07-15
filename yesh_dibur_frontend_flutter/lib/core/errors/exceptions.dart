// נזרק כאשר השרת מחזיר קוד שגיאה (למשל 400 או 500)
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});
}

// נזרק כאשר אין חיבור אינטרנט או שהבקשה נכשלה לחלוטין
class NetworkException implements Exception {
  final String message;
  
  NetworkException({this.message = 'שגיאת רשת, אנא בדוק את החיבור לאינטרנט ונסה שוב'});
}