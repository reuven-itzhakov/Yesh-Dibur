import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/exceptions.dart';
import 'models/thread_model.dart';

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ThreadRepository(dio: ref.read(dioProvider));
});

class ThreadRepository {
  final Dio dio;

  ThreadRepository({required this.dio});

  Future<ThreadModel> createThread({
    required String groupId,
    required String content,
    required String bgType, // 'color' או 'image'
    required String bgValue, // קוד צבע או נתיב תמונה זמני
    File? imageFile, // הקובץ עצמו (אם נבחרה תמונה)
  }) async {
    try {
      String finalBgValue = bgValue;

      // אם המשתמש בחר להעלות תמונה מהגלריה
      if (bgType == 'image' && imageFile != null) {
        final fileName = 'threads/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        
        await ref.putFile(imageFile);
        finalBgValue = await ref.getDownloadURL();
      }

      final response = await dio.post(
        ApiConstants.threads,
        data: {
          'group_id': groupId,
          'content': content,
          'bg_type': bgType,
          'bg_value': finalBgValue,
        },
      );

      return ThreadModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['error'] ?? 'שגיאה ביצירת הפוסט',
      );
    } catch (e) {
      throw ServerException(message: 'שגיאה לא צפויה: $e');
    }
  }
}