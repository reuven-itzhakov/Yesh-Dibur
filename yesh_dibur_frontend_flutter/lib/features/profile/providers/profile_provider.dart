import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../repositories/user_repository.dart';

final profileProvider = StateNotifierProvider.autoDispose<ProfileNotifier, AsyncValue<ProfileModel>>((ref) {
  return ProfileNotifier(ref);
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel>> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ref.read(userRepositoryProvider).getProfile();
      if (mounted) state = AsyncValue.data(profile);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateProfileDetails(String name, String bio) async {
    state = const AsyncValue.loading();
    try {
      final updatedProfile = await ref.read(userRepositoryProvider).updateProfile(name: name, bio: bio);
      if (mounted) state = AsyncValue.data(updatedProfile);
      return true;
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendLocationUpdate() async {
    try {
      // לפיתוח בלבד: נשלח קואורדינטות קבועות של תל אביב (או כל מקום אחר)
      // בפרודקשן נחליף זאת בחבילת geolocator לשליפת GPS אמיתי
      await ref.read(userRepositoryProvider).updateLocation(32.0853, 34.7818);
      return true;
    } catch (e) {
      return false;
    }
  }
}