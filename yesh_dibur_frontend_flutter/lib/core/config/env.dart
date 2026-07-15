import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // שולף את כתובת השרת, עם גיבוי ל-localhost במקרה של שגיאה
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
}