import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/chat_inbox_provider.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(chatInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('הודעות'),
      ),
      body: inboxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('שגיאה בטעינת ההודעות: $err')),
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text('אין לך שיחות פעילות כרגע.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(chatInboxProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.muted,
                    child: Icon(Icons.person, color: AppTheme.mutedForeground),
                  ),
                  title: Text(
                    chat.otherUserName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat.lastMessageContent ?? 'תמונה מצורפת',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chat.unreadCount > 0 ? AppTheme.foreground : AppTheme.mutedForeground,
                      fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: chat.unreadCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      : null,
                  onTap: () {
                    // מעבר למסך הצ'אט הספציפי (נבנה אותו בשלב הבא)
                    context.push('/chat/${chat.id}/${chat.otherUserName}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}