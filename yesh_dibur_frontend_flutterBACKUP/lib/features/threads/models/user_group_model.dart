class UserGroupModel {
  final String id;
  final String name;

  UserGroupModel({required this.id, required this.name});

  factory UserGroupModel.fromJson(Map<String, dynamic> json) {
    return UserGroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'קבוצה ללא שם',
    );
  }
}