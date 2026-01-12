import 'package:lockmess/core/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  Future<void> logout();
  Future<Profile> getProfile(String uuid);
  Future<Profile> getCurrentProfile();
  Future<void> updateProfile(Profile profile);
  Future<bool> isUsernameAvailable(String username, String currentUserId);
}
