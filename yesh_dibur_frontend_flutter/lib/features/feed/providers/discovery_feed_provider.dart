import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feed_repository.dart';
import '../data/models/thread_model.dart';

// ה-Provider שנחשוף לממשק המשתמש (UI)
final discoveryFeedProvider = AsyncNotifierProvider<DiscoveryFeedNotifier, List<ThreadModel>>(() {
  return DiscoveryFeedNotifier();
});

class DiscoveryFeedNotifier extends AsyncNotifier<List<ThreadModel>> {
  String? _cursor;
  bool _hasReachedMax = false;
  bool _isFetchingMore = false; // מונע קריאות כפולות בזמן גלילה

  @override
  Future<List<ThreadModel>> build() async {
    // איפוס משתני העימוד בכל פעם שהפיד נטען מחדש
    _cursor = null;
    _hasReachedMax = false;
    return _fetchInitial();
  }

  Future<List<ThreadModel>> _fetchInitial() async {
    final repository = ref.read(feedRepositoryProvider);
    
    // משיכת 20 הפוסטים הראשונים
    final threads = await repository.getDiscoveryFeed(limit: 20);
    
    if (threads.length < 20) {
      _hasReachedMax = true; // הגענו לסוף מסד הנתונים
    } else {
      // נניח שזיהוי הפוסט האחרון הוא ה-Cursor שלנו למנה הבאה
      _cursor = threads.last.id; 
    }
    
    return threads;
  }

  // הפונקציה שתוזנק מגלילת המשתמש (Infinite Scroll)
  Future<void> fetchNextPage() async {
    // עצירה אם אנחנו כבר בטעינה, הגענו לסוף, או שיש שגיאה במסך
    if (_hasReachedMax || _isFetchingMore || state.isLoading || state.hasError) return;

    _isFetchingMore = true;
    
    try {
      final repository = ref.read(feedRepositoryProvider);
      final newThreads = await repository.getDiscoveryFeed(cursor: _cursor, limit: 20);

      if (newThreads.isEmpty) {
        _hasReachedMax = true;
      } else {
        if (newThreads.length < 20) {
          _hasReachedMax = true;
        }
        _cursor = newThreads.last.id;
        
        // הוספת הפוסטים החדשים לרשימה הקיימת מבלי לדרוס אותה
        state = AsyncData([...state.value ?? [], ...newThreads]);
      }
    } catch (e) {
      // לא משנים את הסטייט ל-Error כדי לא למחוק את הפיד הקיים.
      // אפשר להוסיף כאן לוגיקה שמקפיצה שגיאת סנאקבר על כשל במשיכת המנה הבאה.
      print('שגיאה במשיכת העמוד הבא: $e');
    } finally {
      _isFetchingMore = false;
    }
  }
}