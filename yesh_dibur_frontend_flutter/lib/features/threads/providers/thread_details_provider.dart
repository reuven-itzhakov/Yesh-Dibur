import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/errors/exceptions.dart';
import '../../feed/models/thread_model.dart';
import '../models/comment_model.dart';
import '../repositories/thread_repository.dart';

// פרובידר לשליפת הפוסט עצמו (עם ניקוי אוטומטי ביציאה מהמסך)
final threadDetailsProvider = FutureProvider.autoDispose.family<ThreadModel, String>((ref, threadId) async {
  return ref.read(threadRepositoryProvider).getThread(threadId);
});

// שימוש ב-StateNotifierProvider שעוקף את בעיית הטיפוסים (Type Bounds)
final commentsNotifierProvider = StateNotifierProvider.autoDispose.family<CommentsNotifier, AsyncValue<List<CommentModel>>, String>((ref, threadId) {
  return CommentsNotifier(ref, threadId);
});

class CommentsNotifier extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final Ref ref;
  final String threadId;

  // אתחול המצב לטעינה ושליפת התגובות באופן מיידי
  CommentsNotifier(this.ref, this.threadId) : super(const AsyncValue.loading()) {
    _loadInitialComments();
  }

  Future<void> _loadInitialComments() async {
    try {
      final comments = await ref.read(threadRepositoryProvider).getComments(threadId);
      if (mounted) state = AsyncValue.data(comments);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(ServerException(e.toString()), st);
    }
  }

  Future<bool> addComment(String content) async {
    if (content.trim().isEmpty) return false;
    
    final currentComments = state.value ?? [];
    state = const AsyncValue.loading();
    
    try {
      final newComment = await ref.read(threadRepositoryProvider).createComment(threadId, content);
      
      // מוסיפים את התגובה החדשה לסוף הרשימה מבלי לרענן הכל מהשרת
      if (mounted) state = AsyncValue.data([...currentComments, newComment]);
      return true;
    } on ValidationException catch (e) {
      if (mounted) state = AsyncValue.error(e, StackTrace.current);
      return false;
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(ServerException(e.toString()), st);
      return false;
    }
  }
}