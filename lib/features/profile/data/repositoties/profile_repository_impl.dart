import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/core/utils/get_user_info.dart';
import 'package:lockmess/core/domain/entities/profile.dart';
import 'package:lockmess/features/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl(ref.read(supabase));
});

final class ProfileRepositoryImpl
    with GetUserInfo
    implements ProfileRepository {
  final Supabase _supabase;
  Profile profile = Profile(
    id: '',
    displayName: '',
    username: '',
    phone: '',
    gender: '',
    email: '',
    avatarUrl: '',
    birthday: '',
    hobbies: [],
  );

  ProfileRepositoryImpl(this._supabase);

  @override
  Future<void> logout() async {
    await _supabase.client.auth.signOut();
  }

  @override
  void updateProfile() {
    // TODO: implement updateProfile
  }

  @override
  Future<Profile> getProfile(String uuid) async {
    print('uuid ${uuid}');
    if (uuid == profile.id) return profile;
    final rawUser = await _supabase.client
        .from('profiles')
        .select()
        .eq('id', uuid);
    print(rawUser);

    // handle user do not exsist in database
    if (rawUser.isEmpty) {
      final currentUser = _supabase.client.auth.currentUser;
      final displayName = getNameFromMetadata(currentUser?.userMetadata);
      final avatarUrl = getAvatarFromMetadata(currentUser?.userMetadata);

      try {
        await _supabase.client.from('profiles').insert({
          'id': currentUser?.id,
          'display_name': displayName,
          'username': 'user${currentUser?.id.substring(0, 7)}',
          // 'phone': currentUser?.phone,
          // 'gender': null,
          // 'birthday': null,
          'email': currentUser?.email,
          'avatar_url': avatarUrl,
        });
      } catch (e) {
        print(e);
      }

      profile = Profile(
        id: currentUser!.id,
        displayName: displayName,
        username: 'user${currentUser.id.substring(0, 7)}',
        phone: currentUser.phone!,
        gender: '',
        email: currentUser.email!,
        avatarUrl: avatarUrl,
        birthday: '',
        hobbies: [],
      );
      return profile;
    }

    // get hobbies
    final hobbies = getHobbies(
      await _supabase.client
          .from('profiles')
          .select('hobbies(name)')
          .eq('id', uuid),
    );

    final user = parseUser(rawUser.first);
    print('user id from repo: ${user.id}');
    profile = Profile(
      id: user.id,
      displayName: user.displayName,
      username: user.username,
      phone: user.phone,
      gender: user.gender,
      email: user.email,
      avatarUrl: user.avatarUrl,
      birthday: user.birthday,
      hobbies: hobbies,
    );
    return profile;
  }
}
