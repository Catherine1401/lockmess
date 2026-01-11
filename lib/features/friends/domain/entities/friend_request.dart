class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.status,
    required this.createdAt,
  });
}
