import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService() : _storage = const FlutterSecureStorage();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _isFirstLaunchKey = 'is_first_launch';

  // --- ניהול FCM Token ---
  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  Future<void> deleteFcmToken() async {
    await _storage.delete(key: _fcmTokenKey);
  }

  // --- ניהול מצב הפעלה ראשונית (לצורך הצגת Onboarding פעם אחת) ---
  Future<void> setFirstLaunchCompleted() async {
    await _storage.write(key: _isFirstLaunchKey, value: 'false');
  }

  Future<bool> isFirstLaunch() async {
    final value = await _storage.read(key: _isFirstLaunchKey);
    return value == null || value == 'true';
  }

  // ניקוי כללי בעת התנתקות
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}