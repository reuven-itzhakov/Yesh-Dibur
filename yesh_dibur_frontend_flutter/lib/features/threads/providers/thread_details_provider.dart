import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/exceptions.dart';
import '../../feed/models/thread_model.dart';
import '../models/comment_model.dart';
import '../repositories/thread_repository.dart';

// חובה להוסיף את השורה הזו כדי שהגנרטור ייצור את הקובץ
part 'thread_details_provider.g.dart';

// פונקציה פשוטה שמחליפה את ה-FutureProvider.family המסורבל
@riverpod
Future<ThreadModel> threadDetails(ThreadDetailsRef ref, String threadId) async {
  return ref.read(threadRepositoryProvider).getThread(threadId);
}

// מחלקה נקייה שמחליפה את ה-StateNotifier המשוגע שהיה לנו
@riverpod
class Comments extends _$Comments {
  @override
  FutureOr<List<CommentModel>> build(String threadId) async {
    // השליפה הראשונית מתבצעת כאן ישירות
    return ref.read(threadRepositoryProvider).getComments(threadId);
  }

  Future<bool> addComment(String content) async {
    if (content.trim().isEmpty) return false;

    final currentComments = state.value ?? [];
    state = const AsyncValue.loading();

    try {
      final newComment = await ref.read(threadRepositoryProvider).createComment(threadId, content);
      state = AsyncValue.data([...currentComments, newComment]);
      return true;
    } on ValidationException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(ServerException(e.toString()), st);
      return false;
    }
  }
}