import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/thread_repository.dart';

final createThreadProvider = StateNotifierProvider<CreateThreadNotifier, AsyncValue<void>>((ref) {
  return CreateThreadNotifier(ref.read(threadRepositoryProvider));
});

class CreateThreadNotifier extends StateNotifier<AsyncValue<void>> {
  final ThreadRepository repository;

  CreateThreadNotifier(this.repository) : super(const AsyncData(null));

  Future<bool> createThread({
    required String groupId,
    required String content,
    required String bgType,
    required String bgValue,
    File? imageFile,
  }) async {
    state = const AsyncLoading();
    
    try {
      await repository.createThread(
        groupId: groupId,
        content: content,
        bgType: bgType,
        bgValue: bgValue,
        imageFile: imageFile,
      );
      
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}