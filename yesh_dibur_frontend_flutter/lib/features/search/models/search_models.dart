class SearchResponse {
  final List<UserSearchResult> users;
  final List<GroupSearchResult> groups;

  SearchResponse({required this.users, required this.groups});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final usersList = (data['users'] as List?) ?? [];
    final groupsList = (data['groups'] as List?) ?? [];

    return SearchResponse(
      users: usersList.map((e) => UserSearchResult.fromJson(e)).toList(),
      groups: groupsList.map((e) => GroupSearchResult.fromJson(e)).toList(),
    );
  }
}

class UserSearchResult {
  final String id;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final String? locationLabel;
  final num? age;

UserSearchResult({
    required this.id,
    required this.name,
    this.bio,
    this.profileImageUrl,
    this.locationLabel,
    this.age,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    // הוספנו המרה בטוחה למספר כדי לטפל במקרה שהשרת מחזיר מחרוזת כמו "25"
    num? parsedAge;
    if (json['age'] != null) {
      parsedAge = num.tryParse(json['age'].toString());
    }

    return UserSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? 'משתמש',
      bio: json['bio'],
      profileImageUrl: json['profile_image_url'],
      locationLabel: json['location_label'],
      age: parsedAge,
    );
  }
}

class GroupSearchResult {
  final String id;
  final String name;
  final String? description;
  final String? groupImage;
  final int membersCount;
  final bool isMember;

  GroupSearchResult({
    required this.id,
    required this.name,
    this.description,
    this.groupImage,
    required this.membersCount,
    required this.isMember,
  });

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    return GroupSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? 'קבוצה',
      description: json['description'],
      groupImage: json['group_image'],
      membersCount: int.tryParse(json['members_count']?.toString() ?? '0') ?? 0,
      isMember: json['is_member'] ?? false,
    );
  }
}