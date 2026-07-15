// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      bio: json['bio'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      tiktokUrl: json['tiktok_url'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      interests: (json['interests'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'birth_date': instance.birthDate.toIso8601String(),
      'location': instance.location,
      'bio': instance.bio,
      'instagram_url': instance.instagramUrl,
      'tiktok_url': instance.tiktokUrl,
      'profile_image_url': instance.profileImageUrl,
      'interests': instance.interests,
    };

_$LocationModelImpl _$$LocationModelImplFromJson(Map<String, dynamic> json) =>
    _$LocationModelImpl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$$LocationModelImplToJson(_$LocationModelImpl instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};
