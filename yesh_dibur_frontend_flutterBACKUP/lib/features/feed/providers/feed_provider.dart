import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/thread_model.dart';
import '../repositories/feed_repository.dart';

// --- פיד גילוי (Discovery) ---
final discoveryFeedProvider = AsyncNotifierProvider<DiscoveryFeedNotifier, List<ThreadModel>>(() {
  return DiscoveryFeedNotifier();
});

class DiscoveryFeedNotifier extends AsyncNotifier<List<ThreadModel>> {
  String? _cursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  FutureOr<List<ThreadModel>> build() async {
    return _fetchInitial();
  }

  Future<List<ThreadModel>> _fetchInitial() async {
    _cursor = null;
    _hasMore = true;
    final repo = ref.read(feedRepositoryProvider);
    final response = await repo.getDiscoveryFeed();
    _cursor = response.nextCursor;
    _hasMore = response.nextCursor != null;
    return response.threads;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.isLoading || state.hasError) return;

    _isLoadingMore = true;
    try {
      final repo = ref.read(feedRepositoryProvider);
      final response = await repo.getDiscoveryFeed(cursor: _cursor);
      
      _cursor = response.nextCursor;
      _hasMore = response.nextCursor != null;
      
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, ...response.threads]);
    } catch (e, st) {
      // במקרה של שגיאה בטעינת העמוד הבא, לא נדרוס את הרשימה הקיימת
      print('Error loading more discovery feed: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitial());
  }
}

// --- פיד הקבוצות שלי (My Groups) ---
final myGroupsFeedProvider = AsyncNotifierProvider<MyGroupsFeedNotifier, List<ThreadModel>>(() {
  return MyGroupsFeedNotifier();
});

class MyGroupsFeedNotifier extends AsyncNotifier<List<ThreadModel>> {
  String? _cursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  FutureOr<List<ThreadModel>> build() async {
    return _fetchInitial();
  }

  Future<List<ThreadModel>> _fetchInitial() async {
    _cursor = null;
    _hasMore = true;
    final repo = ref.read(feedRepositoryProvider);
    final response = await repo.getMyGroupsFeed();
    _cursor = response.nextCursor;
    _hasMore = response.nextCursor != null;
    return response.threads;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.isLoading || state.hasError) return;

    _isLoadingMore = true;
    try {
      final repo = ref.read(feedRepositoryProvider);
      final response = await repo.getMyGroupsFeed(cursor: _cursor);
      
      _cursor = response.nextCursor;
      _hasMore = response.nextCursor != null;
      
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, ...response.threads]);
    } catch (e) {
      print('Error loading more my groups feed: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitial());
  }
}