class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorImage;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorImage,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? 'משתמש',
      authorImage: json['author_image'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}