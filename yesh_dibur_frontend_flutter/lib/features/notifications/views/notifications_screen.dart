import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('התראות'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'סמן הכל כנקרא',
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
          )
        ],
      ),
      body: notificationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('שגיאה: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('אין התראות חדשות.'));
          }
          return ListView.separated(
            controller: _scrollController,
            itemCount: notifications.length + 1,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              if (index == notifications.length) {
                return const SizedBox(height: 80); // מרווח תחתון למניעת הסתרה מתחת לתפריט
              }
              
              final notification = notifications[index];
              return ListTile(
                tileColor: notification.isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.1),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.muted,
                  child: const Icon(Icons.notifications, color: AppTheme.mutedForeground),
                ),
                title: Text(
                  notification.senderName != null ? 'התראה מ-${notification.senderName}' : 'התראה חדשה',
                  style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text(notification.content ?? 'יש לך עדכון חדש באפליקציה.'),
                onTap: () {
                  if (!notification.isRead) {
                    ref.read(notificationProvider.notifier).markAsRead(notification.id);
                  }
                  // ניווט מותנה יעשה כאן בהמשך לפי ה-type של ההתראה (לדוגמה קפיצה לפוסט מסוים)
                },
              );
            },
          );
        },
      ),
    );
  }
}