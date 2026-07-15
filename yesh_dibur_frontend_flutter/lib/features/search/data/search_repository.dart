import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/exceptions.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(dio: ref.read(dioProvider));
});

class SearchRepository {
  final Dio dio;

  SearchRepository({required this.dio});

  Future<Map<String, dynamic>> search({
    required String query,
    String? type,
    int? radiusKm,
    int? minAge,
    int? maxAge,
    List<String>? interests,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.search,
        queryParameters: {
          'q': query,
          if (type != null) 'type': type,
          if (radiusKm != null) 'radius_km': radiusKm,
          if (minAge != null) 'min_age': minAge,
          if (maxAge != null) 'max_age': maxAge,
          if (interests != null && interests.isNotEmpty) 'interests': interests.join(','),
          'page': page,
          'limit': limit,
        },
      );
      return response.data; // מניחים שהשרת יחזיר אובייקט המכיל 'groups' ו-'users'
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'שגיאה בביצוע החיפוש',
      );
    } catch (e) {
      throw ServerException(message: 'שגיאה לא צפויה: $e');
    }
  }
}