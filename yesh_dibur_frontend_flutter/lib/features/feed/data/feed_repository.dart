import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/thread_model.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final dio = ref.read(dioProvider);
  return FeedRepository(dio: dio);
});

class FeedRepository {
  final Dio dio;

  FeedRepository({required this.dio});

  // משיכת פיד הגילוי (פתוח גם לאורחים)
  Future<List<ThreadModel>> getDiscoveryFeed({
    String? cursor, 
    int limit = 20, 
    int? radiusKm
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.discoveryFeed,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
          if (radiusKm != null) 'radius_km': radiusKm,
        },
      );
      
      // אנו מניחים שהשרת מחזיר אובייקט JSON המכיל מפתח 'data' עם מערך הפוסטים
      final List data = response.data['data'] ?? [];
      return data.map((json) => ThreadModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'שגיאה במשיכת פיד הגילוי',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'שגיאה לא צפויה: $e');
    }
  }

  // משיכת פיד הקבוצות (למשתמשים מחוברים בלבד)
  Future<List<ThreadModel>> getMyGroupsFeed({
    String? cursor, 
    int limit = 20
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.myGroupsFeed,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      
      final List data = response.data['data'] ?? [];
      return data.map((json) => ThreadModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'שגיאה במשיכת פיד הקבוצות',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'שגיאה לא צפויה: $e');
    }
  }
}