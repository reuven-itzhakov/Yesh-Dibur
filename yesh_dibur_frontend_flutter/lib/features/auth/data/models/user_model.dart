import 'package:freezed_annotation/freezed_annotation.dart';

// אלו הקבצים שיחוללו אוטומטית על ידי build_runner
part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id, // Firebase UID
    required String name,
    required String email,
    required String phone,
    @JsonKey(name: 'birth_date') required DateTime birthDate,
    LocationModel? location,
    String? bio,
    @JsonKey(name: 'instagram_url') String? instagramUrl,
    @JsonKey(name: 'tiktok_url') String? tiktokUrl,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    required List<String> interests,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
}

@freezed
class LocationModel with _$LocationModel {
  const factory LocationModel({
    required double lat,
    required double lng,
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) => 
      _$LocationModelFromJson(json);
}