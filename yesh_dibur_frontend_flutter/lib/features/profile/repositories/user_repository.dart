import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../threads/models/user_group_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(dioProvider));
});

class UserRepository {
  final Dio _dio;
  UserRepository(this._dio);

  Future<List<UserGroupModel>> getMyGroups() async {
    final response = await _dio.get('/users/groups');
    final dataList = response.data as List;
    return dataList.map((json) => UserGroupModel.fromJson(json)).toList();
  }
}