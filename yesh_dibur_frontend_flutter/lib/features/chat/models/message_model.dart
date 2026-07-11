class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl;
  final String status; // 'pending_approval', 'approved', 'read'
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      status: json['status'] ?? 'approved',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}