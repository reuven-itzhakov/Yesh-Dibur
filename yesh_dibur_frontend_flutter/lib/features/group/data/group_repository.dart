import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/group_model.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(dio: ref.read(dioProvider));
});

class GroupRepository {
  final Dio dio;

  GroupRepository({required this.dio});

  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required List<String> interests,
    File? coverImage,
  }) async {
    try {
      String? coverUrl;

      // אם המשתמש בחר תמונה, קודם נעלה אותה ל-Firebase Storage
      if (coverImage != null) {
        // נייצר שם קובץ ייחודי לפי חותמת זמן
        final fileName = 'groups/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        
        await ref.putFile(coverImage);
        coverUrl = await ref.getDownloadURL();
      }

      // שליחת הנתונים לשרת ה-Node.js כולל כתובת התמונה (אם יש)
      final response = await dio.post(
        ApiConstants.groups,
        data: {
          'name': name,
          'description': description,
          'interests': interests,
          if (coverUrl != null) 'cover_image': coverUrl,
        },
      );

      return GroupModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'שגיאה ביצירת הקבוצה',
      );
    } catch (e) {
      throw ServerException(message: 'שגיאה לא צפויה: $e');
    }
  }
}