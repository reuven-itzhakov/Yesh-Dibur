class CreateThreadRequest {
  final String groupId;
  final String content;
  final String bgType;
  final String bgValue;
  final double? aspectRatio;

  CreateThreadRequest({
    required this.groupId,
    required this.content,
    required this.bgType,
    required this.bgValue,
    this.aspectRatio,
  });

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'content': content.trim(),
      'bg_type': bgType,
      'bg_value': bgValue,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
    };
  }
}