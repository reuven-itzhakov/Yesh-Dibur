import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/exceptions.dart';
import '../models/create_group_request.dart';
import '../repositories/group_repository.dart';

final groupControllerProvider = AsyncNotifierProvider<GroupController, void>(() {
  return GroupController();
});

class GroupController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createGroup(CreateGroupRequest request) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.createGroup(request);
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