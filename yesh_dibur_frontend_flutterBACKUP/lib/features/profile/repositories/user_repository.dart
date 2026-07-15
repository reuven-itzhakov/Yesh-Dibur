import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../threads/models/user_group_model.dart';
import '../models/profile_model.dart';

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

  Future<ProfileModel> getProfile() async {
    final response = await _dio.get('/users/profile');
    return ProfileModel.fromJson(response.data);
  }

  Future<ProfileModel> updateProfile({String? name, String? bio}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;

    final response = await _dio.put('/users/profile', data: data);
    return ProfileModel.fromJson(response.data);
  }

  Future<void> updateLocation(double lat, double lng) async {
    await _dio.put('/users/location', data: {
      'latitude': lat,
      'longitude': lng,
    });
  }
}