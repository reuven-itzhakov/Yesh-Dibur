class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? profileImageUrl;
  final String? fcmToken;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.profileImageUrl,
    this.fcmToken,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      profileImageUrl: json['profile_image_url'],
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  ProfileModel copyWith({
    String? name,
    String? bio,
    String? profileImageUrl,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken,
      createdAt: createdAt,
    );
  }
}