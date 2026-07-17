import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';

// אנו משתמשים ב-StateNotifier עם AsyncValue כדי לנהל מצבי טעינה/הצלחה/שגיאה בקלות
final createGroupProvider = StateNotifierProvider<CreateGroupNotifier, AsyncValue<void>>((ref) {
  return CreateGroupNotifier(ref.read(groupRepositoryProvider));
});

class CreateGroupNotifier extends StateNotifier<AsyncValue<void>> {
  final GroupRepository repository;

  CreateGroupNotifier(this.repository) : super(const AsyncData(null));

  Future<bool> createGroup({
    required String name,
    required String description,
    required List<String> interests,
    File? coverImage,
  }) async {
    state = const AsyncLoading(); // התחלת טעינה
    
    try {
      await repository.createGroup(
        name: name,
        description: description,
        interests: interests,
        coverImage: coverImage,
      );
      
      state = const AsyncData(null); // הצלחה
      return true;
    } catch (e, st) {
      state = AsyncError(e, st); // שגיאה
      return false;
    }
  }
}