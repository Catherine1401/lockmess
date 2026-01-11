import 'package:lockmess/features/friends/domain/entities/friend_request.dart';
import 'package:lockmess/core/domain/entities/profile.dart';

abstract class FriendRepository {
  Future<List<Profile>> getFriends();
  Future<List<FriendRequest>> getFriendRequests();
  Future<List<Profile>> searchUsers(String query);

  // Returns status: 'none', 'friend', 'sent', 'received'
  Future<String> getFriendStatus(String targetId);

  Future<void> sendFriendRequest(String targetId);
  Future<void> acceptFriendRequest(String senderId);
  Future<void> declineFriendRequest(String senderId);
  Future<void> unfriend(String targetId);
  Future<void> cancelFriendRequest(String targetId);
}
