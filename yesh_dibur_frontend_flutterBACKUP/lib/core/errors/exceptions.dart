class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  // ממפה שם שדה (כמו 'email') להודעת השגיאה מ-Zod
  final Map<String, String> errors;
  ValidationException(this.errors);

  @override
  String toString() => 'Validation errors: $errors';
}