class ThreadModel {
  final String id;
  final String content;
  final String bgType; // 'image' or 'color'
  final String bgValue;
  final double? aspectRatio;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  
  final String authorId;
  final String authorName;
  final String? authorImage;
  
  final String groupId;
  final String groupName;
  final String? groupImage;
  
  final bool isLiked;
  final String? locationLabel; // חוזר רק בפיד גילוי (לדוגמה: 'במרחק 2 ק"מ')

  ThreadModel({
    required this.id,
    required this.content,
    required this.bgType,
    required this.bgValue,
    this.aspectRatio,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.authorImage,
    required this.groupId,
    required this.groupName,
    this.groupImage,
    required this.isLiked,
    this.locationLabel,
  });

  factory ThreadModel.fromJson(Map<String, dynamic> json) {
    return ThreadModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      bgType: json['bg_type'] ?? 'color',
      bgValue: json['bg_value'] ?? '#000000',
      aspectRatio: json['aspect_ratio'] != null ? (json['aspect_ratio'] as num).toDouble() : null,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? 'משתמש',
      authorImage: json['author_image'],
      groupId: json['group_id'] ?? '',
      groupName: json['group_name'] ?? 'קבוצה',
      groupImage: json['group_image'],
      isLiked: json['is_liked'] ?? false,
      locationLabel: json['location_label'],
    );
  }
}