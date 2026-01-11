import 'package:lockmess/core/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  Future<void> logout();
  void updateProfile();
  Future<Profile> getProfile(String uuid);
}
