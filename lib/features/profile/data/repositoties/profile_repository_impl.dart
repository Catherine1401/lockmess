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
  Future<Profile> getCurrentProfile() async {
    final currentUser = _supabase.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    return await getProfile(currentUser.id);
  }

  @override
  Future<void> updateProfile(Profile updatedProfile) async {
    try {
      // Update main profile fields
      await _supabase.client
          .from('profiles')
          .update({
            'display_name': updatedProfile.displayName,
            'username': updatedProfile.username,
            'phone': updatedProfile.phone.isEmpty ? null : updatedProfile.phone,
            'gender': updatedProfile.gender,
            'avatar_url': updatedProfile.avatarUrl,
            'birthday': updatedProfile.birthday,
          })
          .eq('id', updatedProfile.id);

      // Update hobbies
      // Use upsert with onConflict to handle existing records

      if (updatedProfile.hobbies.isNotEmpty) {
        final hobbiesData = await _supabase.client
            .from('hobbies')
            .select('id, name')
            .inFilter('name', updatedProfile.hobbies);

        // Ensure unique hobby IDs
        final hobbyIds = hobbiesData.map((h) => h['id']).toSet().toList();

        if (hobbyIds.isNotEmpty) {
          // First, delete hobbies that are no longer selected
          final existingHobbies = await _supabase.client
              .from('profiles_hobbies')
              .select('hobby_id')
              .eq('user_id', updatedProfile.id);

          final existingHobbyIds = existingHobbies
              .map((h) => h['hobby_id'])
              .toSet();

          final hobbyIdsToDelete = existingHobbyIds.difference(
            hobbyIds.toSet(),
          );

          // Delete removed hobbies
          if (hobbyIdsToDelete.isNotEmpty) {
            await _supabase.client
                .from('profiles_hobbies')
                .delete()
                .eq('user_id', updatedProfile.id)
                .inFilter('hobby_id', hobbyIdsToDelete.toList());
          }

          // Upsert new/existing hobbies with onConflict
          final associations = hobbyIds
              .map(
                (hobbyId) => {
                  'user_id': updatedProfile.id,
                  'hobby_id': hobbyId,
                },
              )
              .toList();

          await _supabase.client
              .from('profiles_hobbies')
              .upsert(associations, onConflict: 'user_id,hobby_id');
        }
      } else {
        // If no hobbies selected, delete all associations
        await _supabase.client
            .from('profiles_hobbies')
            .delete()
            .eq('user_id', updatedProfile.id);
      }

      // Update local cache
      profile = updatedProfile;
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isUsernameAvailable(
    String username,
    String currentUserId,
  ) async {
    try {
      final result = await _supabase.client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', currentUserId)
          .maybeSingle();

      return result == null; // Available if no result found
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
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
