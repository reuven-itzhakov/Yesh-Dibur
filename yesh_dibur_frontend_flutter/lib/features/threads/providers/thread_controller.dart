import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/exceptions.dart';
import '../../profile/repositories/user_repository.dart';
import '../models/create_thread_request.dart';
import '../models/user_group_model.dart';
import '../repositories/thread_repository.dart';

// פרובידר פשוט שקורא לשרת פעם אחת ומביא את רשימת הקבוצות שלי
final userGroupsProvider = FutureProvider.autoDispose<List<UserGroupModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getMyGroups();
});

final threadControllerProvider = AsyncNotifierProvider<ThreadController, void>(() {
  return ThreadController();
});

class ThreadController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createThread(CreateThreadRequest request) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(threadRepositoryProvider);
      await repo.createThread(request);
      state = const AsyncValue.data(null);
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