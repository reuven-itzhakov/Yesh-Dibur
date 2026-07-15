import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feed_repository.dart';
import '../data/models/thread_model.dart';
// נייבא את ה-authProvider שלנו כדי לבדוק אם המשתמש מחובר
import '../../auth/providers/auth_provider.dart'; 

final myGroupsFeedProvider = AsyncNotifierProvider<MyGroupsFeedNotifier, List<ThreadModel>>(() {
  return MyGroupsFeedNotifier();
});

class MyGroupsFeedNotifier extends AsyncNotifier<List<ThreadModel>> {
  String? _cursor;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false;

  @override
  Future<List<ThreadModel>> build() async {
    // נוודא שהמשתמש מחובר. אם הוא אורח, נחזיר רשימה ריקה מיד.
    final authState = ref.watch(authProvider);
    if (authState.value == null) {
      return [];
    }

    _cursor = null;
    _hasReachedMax = false;
    return _fetchInitial();
  }

  Future<List<ThreadModel>> _fetchInitial() async {
    final repository = ref.read(feedRepositoryProvider);
    final threads = await repository.getMyGroupsFeed(limit: 20);
    
    if (threads.length < 20) {
      _hasReachedMax = true;
    } else {
      _cursor = threads.last.id; 
    }
    
    return threads;
  }

  Future<void> fetchNextPage() async {
    if (_hasReachedMax || _isFetchingMore || state.isLoading || state.hasError) return;

    _isFetchingMore = true;
    
    try {
      final repository = ref.read(feedRepositoryProvider);
      final newThreads = await repository.getMyGroupsFeed(cursor: _cursor, limit: 20);

      if (newThreads.isEmpty) {
        _hasReachedMax = true;
      } else {
        if (newThreads.length < 20) {
          _hasReachedMax = true;
        }
        _cursor = newThreads.last.id;
        state = AsyncData([...state.value ?? [], ...newThreads]);
      }
    } catch (e) {
      print('שגיאה במשיכת העמוד הבא (הקבוצות שלי): $e');
    } finally {
      _isFetchingMore = false;
    }
  }
}