import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../models/create_group_request.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.read(dioProvider));
});

class GroupRepository {
  final Dio _dio;

  GroupRepository(this._dio);

  Future<void> createGroup(CreateGroupRequest request) async {
    // ה-AuthInterceptor מזריק כאן את הטוקן, וה-ErrorInterceptor תופס שגיאות 400
    await _dio.post('/groups', data: request.toJson());
  }
}