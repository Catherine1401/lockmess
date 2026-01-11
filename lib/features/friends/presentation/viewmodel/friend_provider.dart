import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/features/friends/data/repositories/friend_repository_impl.dart';
import 'package:lockmess/features/friends/domain/entities/friend_request.dart';
import 'package:lockmess/core/domain/entities/profile.dart';

// --- Providers ---

// 1. Friends List
final friendsListProvider = FutureProvider.autoDispose<List<Profile>>((ref) {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getFriends();
});

// 2. Friend Requests List
final friendRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>((
  ref,
) {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getFriendRequests();
});

// 3. Search Users
final searchUsersProvider = FutureProvider.family
    .autoDispose<List<Profile>, String>((ref, query) {
      final repo = ref.watch(friendRepositoryProvider);
      return repo.searchUsers(query);
    });

// 4. Friend Status Provider
final friendStatusProvider = FutureProvider.family.autoDispose<String, String>((
  ref,
  targetId,
) {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getFriendStatus(targetId);
});

// --- Controller for Actions ---
// Simple provider that exposes methods
final friendControllerProvider = Provider<FriendController>((ref) {
  return FriendController(ref);
});

class FriendController {
  final Ref ref;
  FriendController(this.ref);

  Future<void> sendRequest(String targetId) async {
    await ref.read(friendRepositoryProvider).sendFriendRequest(targetId);
    ref.invalidate(friendStatusProvider(targetId));
  }

  Future<void> acceptRequest(String senderId) async {
    await ref.read(friendRepositoryProvider).acceptFriendRequest(senderId);
    ref.invalidate(friendsListProvider);
    ref.invalidate(friendRequestsProvider);
  }

  Future<void> declineRequest(String senderId) async {
    await ref.read(friendRepositoryProvider).declineFriendRequest(senderId);
    ref.invalidate(friendRequestsProvider);
  }

  Future<void> unfriend(String targetId) async {
    await ref.read(friendRepositoryProvider).unfriend(targetId);
    ref.invalidate(friendsListProvider);
    ref.invalidate(friendStatusProvider(targetId));
  }

  Future<void> cancelRequest(String targetId) async {
    await ref.read(friendRepositoryProvider).cancelFriendRequest(targetId);
    ref.invalidate(friendStatusProvider(targetId));
  }
}
