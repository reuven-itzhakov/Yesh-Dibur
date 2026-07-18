import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../data/models/group_model.dart';

final myGroupsListProvider = FutureProvider<List<GroupModel>>((ref) async {
  final repository = ref.read(groupRepositoryProvider);
  return repository.getMyGroups();
});