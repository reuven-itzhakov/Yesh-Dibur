class ChatConversationModel {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? profileImageUrl;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.profileImageUrl,
    this.lastMessageContent,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id'] ?? '',
      otherUserId: json['other_user_id'] ?? '',
      otherUserName: json['other_user_name'] ?? 'משתמש',
      profileImageUrl: json['profile_image_url'],
      lastMessageContent: json['last_message_content'],
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.parse(json['last_message_time']) 
          : null,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }
}