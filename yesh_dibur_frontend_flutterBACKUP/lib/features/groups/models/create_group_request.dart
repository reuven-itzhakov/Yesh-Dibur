class CreateGroupRequest {
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<String> interests;

  CreateGroupRequest({
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.interests,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (description != null && description!.trim().isNotEmpty) 'description': description!.trim(),
      if (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty) 'cover_image_url': coverImageUrl!.trim(),
      'interests': interests,
    };
  }
}