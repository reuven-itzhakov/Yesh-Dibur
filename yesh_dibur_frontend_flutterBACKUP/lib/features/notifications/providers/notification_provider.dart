import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

final notificationProvider = StateNotifierProvider.autoDispose<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier(ref);
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref ref;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  NotificationNotifier(this.ref) : super(const AsyncValue.loading()) {
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    _page = 1;
    _hasMore = true;
    try {
      final notifications = await ref.read(notificationRepositoryProvider).getNotifications(page: _page);
      _hasMore = notifications.length == 20;
      if (mounted) state = AsyncValue.data(notifications);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.hasError) return;

    _isLoadingMore = true;
    try {
      _page++;
      final newNotifications = await ref.read(notificationRepositoryProvider).getNotifications(page: _page);
      _hasMore = newNotifications.length == 20;

      final currentList = state.value ?? [];
      if (mounted) state = AsyncValue.data([...currentList, ...newNotifications]);
    } catch (e) {
      _page--; // מחזירים את העמוד אחורה במקרה של שגיאה כדי לנסות שוב
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
      final currentList = state.value ?? [];
      final updatedList = currentList.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      if (mounted) state = AsyncValue.data(updatedList);
    } catch (e) {
      // אם שגיאה מתרחשת אפשר להדפיס או להציג סנאקבר, אך נשאיר זאת שקוף כרגע למניעת הפרעה למשתמש
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      final currentList = state.value ?? [];
      final updatedList = currentList.map((n) => n.copyWith(isRead: true)).toList();
      if (mounted) state = AsyncValue.data(updatedList);
    } catch (e) {
      // התעלמות זהירה במידה ואין אינטרנט זמנית
    }
  }
}