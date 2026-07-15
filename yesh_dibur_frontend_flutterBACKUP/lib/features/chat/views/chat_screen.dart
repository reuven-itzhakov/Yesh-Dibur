import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_messages_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  // שים לב: אנחנו נצטרך את ה-receiverId כדי לשלוח הודעה לפי האפיון שלך. 
  // כרגע נשתמש במזהה זמני (Dummy), בשלב הבא נוודא שהמודל של האינבוקס מעביר אותו לכאן.

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final content = _messageController.text;
    if (content.isEmpty) return;

    _messageController.clear();
    final success = await ref.read(chatMessagesProvider(widget.chatId).notifier).sendMessage(content, widget.receiverId);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה בשליחת ההודעה'), backgroundColor: Colors.red),
      );
      _messageController.text = content; // החזרת הטקסט במקרה של שגיאה
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: AppTheme.card,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('שגיאה: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('התחל את השיחה!'));
                }
                return ListView.builder(
                  reverse: true, // ההודעות החדשות יופיעו למטה
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primary : AppTheme.muted,
                          borderRadius: BorderRadius.circular(AppTheme.darkTheme.cardTheme.shape != null ? 14 : 14),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(color: isMe ? Colors.white : AppTheme.foreground),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.card,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) {
                        // הפעלת חיווי הקלדה בכל פעם שהמשתמש מקליד תו
                        ref.read(chatMessagesProvider(widget.chatId).notifier).notifyTyping();
                      },
                      decoration: const InputDecoration(
                        hintText: 'הקלד הודעה...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primary),
                    onPressed: _sendMessage,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}