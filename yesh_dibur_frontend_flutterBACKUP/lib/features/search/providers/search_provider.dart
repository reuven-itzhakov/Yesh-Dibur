import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_models.dart';
import '../repositories/search_repository.dart';

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier, AsyncValue<SearchResponse>>((ref) {
  return SearchNotifier(ref);
});

class SearchNotifier extends StateNotifier<AsyncValue<SearchResponse>> {
  final Ref ref;
  String _currentQuery = '';

  SearchNotifier(this.ref) : super(const AsyncValue.loading()) {
    // מביא תוצאות התחלתיות (גילוי ללא מילת חיפוש)
    search('');
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(searchRepositoryProvider).performSearch(query: _currentQuery);
      if (mounted) state = AsyncValue.data(response);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}