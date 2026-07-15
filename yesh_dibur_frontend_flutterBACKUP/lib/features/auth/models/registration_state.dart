import 'dart:io';

class RegistrationState {
  final int currentStep;
  final String email;
  final String password;
  final String phone;
  final String verificationId; // עבור Firebase OTP
  final String username;
  final DateTime? birthDate;
  final String? cityName;
  final double? lat;
  final double? lng;
  final List<String> interests;
  final File? profileImage;
  final bool isLoading;
  final String? errorMessage;

  RegistrationState({
    this.currentStep = 0,
    this.email = '',
    this.password = '',
    this.phone = '',
    this.verificationId = '',
    this.username = '',
    this.birthDate,
    this.cityName,
    this.lat,
    this.lng,
    this.interests = const [],
    this.profileImage,
    this.isLoading = false,
    this.errorMessage,
  });

  RegistrationState copyWith({
    int? currentStep,
    String? email,
    String? password,
    String? phone,
    String? verificationId,
    String? username,
    DateTime? birthDate,
    String? cityName,
    double? lat,
    double? lng,
    List<String>? interests,
    File? profileImage,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      verificationId: verificationId ?? this.verificationId,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      cityName: cityName ?? this.cityName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      interests: interests ?? this.interests,
      profileImage: profileImage ?? this.profileImage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // בכוונה לא שם גיבוי כדי לאפשר איפוס שגיאה
    );
  }
}