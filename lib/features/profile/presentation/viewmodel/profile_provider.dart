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
