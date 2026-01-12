import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/features/profile/data/repositoties/profile_repository_impl.dart';
import 'package:lockmess/core/domain/entities/profile.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile>(() {
  return ProfileNotifier();
});

final class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  FutureOr<Profile> build() async {
    // final clm = ref.watch(supabase);
    // print('clm hashcode: ${clm.hashCode}');
    final userId = ref.watch(authProvider).value?.session?.user.id;
    if (userId == null) {
      print('null user');
      return Profile(
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
    }

    print('userid: $userId');
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(userId);
    return profile;
  }
}

// Profile edit controller
final profileEditControllerProvider = Provider<ProfileEditController>((ref) {
  return ProfileEditController(ref);
});

class ProfileEditController {
  final Ref ref;
  ProfileEditController(this.ref);

  Future<void> updateProfile(Profile profile) async {
    try {
      await ref.read(profileRepositoryProvider).updateProfile(profile);
      // Invalidate profile to refresh
      ref.invalidate(profileProvider);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(
    String username,
    String currentUserId,
  ) async {
    return await ref
        .read(profileRepositoryProvider)
        .isUsernameAvailable(username, currentUserId);
  }
}

// All hobbies provider (from database)
final allHobbiesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final supabaseInstance = ref.watch(supabase);
  final hobbiesData = await supabaseInstance.client
      .from('hobbies')
      .select('name')
      .order('name');

  return hobbiesData.map((h) => h['name'] as String).toList();
});
