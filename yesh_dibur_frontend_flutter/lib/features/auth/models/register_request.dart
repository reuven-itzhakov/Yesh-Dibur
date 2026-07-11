class RegisterRequest {
  final String name;
  final String email;
  final String phone;
  final String birthDate;
  final List<String> interests;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.interests,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'birth_date': birthDate,
      'interests': interests,
    };
  }
}