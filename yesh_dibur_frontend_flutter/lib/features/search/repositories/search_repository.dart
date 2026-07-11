import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../models/search_models.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.read(dioProvider));
});

class SearchRepository {
  final Dio _dio;
  SearchRepository(this._dio);

  Future<SearchResponse> performSearch({String query = '', int page = 1}) async {
    final response = await _dio.get(
      '/search',
      queryParameters: {
        if (query.isNotEmpty) 'q': query,
        'type': 'all',
        'page': page,
        'limit': 20,
      },
    );
    return SearchResponse.fromJson(response.data);
  }
}