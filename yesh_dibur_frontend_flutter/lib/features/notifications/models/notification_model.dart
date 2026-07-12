class NotificationModel {
  final String id;
  final String userId;
  final String? senderId;
  final String? senderName;
  final String? senderImage;
  final String type;
  final String? content;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    this.senderName,
    this.senderImage,
    required this.type,
    this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderImage: json['sender_image'],
      type: json['type'] ?? 'general',
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      type: type,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}