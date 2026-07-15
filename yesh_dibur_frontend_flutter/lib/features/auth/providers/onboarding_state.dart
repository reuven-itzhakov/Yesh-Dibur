import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/user_model.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default('') String email,
    @Default('') String password,
    @Default('') String phone,
    DateTime? birthDate,
    LocationModel? location,
    @Default('') String username,
    @Default([]) List<String> interests,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _OnboardingState;
}