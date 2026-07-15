import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/search_repository.dart';
import '../../group/data/models/group_model.dart';
import '../../auth/data/models/user_model.dart';

class SearchState {
  final bool isLoading;
  final List<GroupModel> groups;
  final List<UserModel> users;
  final String? error;

  SearchState({
    this.isLoading = false,
    this.groups = const [],
    this.users = const [],
    this.error,
  });
  
  SearchState copyWith({bool? isLoading, List<GroupModel>? groups, List<UserModel>? users, String? error}) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      groups: groups ?? this.groups,
      users: users ?? this.users,
      error: error ?? this.error,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(searchRepositoryProvider));
});

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository repository;
  Timer? _debounceTimer;

  SearchNotifier(this.repository) : super(SearchState());

  void performSearch(String query) {
    if (query.isEmpty) {
      state = SearchState(); // איפוס תוצאות אם שורת החיפוש ריקה
      return;
    }

    // ביטול הטיימר הקודם אם המשתמש עדיין מקליד (Debounce)
    _debounceTimer?.cancel();
    
    // הגדרת השהיה של 500 מילישניות
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = state.copyWith(isLoading: true, error: null);
      try {
        final results = await repository.search(query: query);
        
        final groupsJson = results['data']['groups'] as List? ?? [];
        final usersJson = results['data']['users'] as List? ?? [];
        
        state = state.copyWith(
          isLoading: false,
          groups: groupsJson.map((g) => GroupModel.fromJson(g)).toList(),
          users: usersJson.map((u) => UserModel.fromJson(u)).toList(),
        );
      } catch (e) {
        state = state.copyWith(isLoading: false, error: 'לא הצלחנו לטעון תוצאות');
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}