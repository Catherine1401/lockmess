import 'package:lockmess/core/domain/entities/profile.dart';

class Conversation {
  final String id;
  final String type; // 'direct', 'group', or 'channel'
  final String? name;
  final String? avatarUrl;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime updatedAt;
  final Profile? otherUser; // For direct chats
  final List<String>? memberIds; // For groups/channels
  final int? memberCount; // For groups/channels

  const Conversation({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    this.lastMessageContent,
    this.lastMessageTime,
    required this.unreadCount,
    required this.updatedAt,
    this.otherUser,
    this.memberIds,
    this.memberCount,
  });

  String get displayName => type == 'direct'
      ? (otherUser?.displayName ?? 'Unknown')
      : (name ?? 'Group');

  String get displayAvatar =>
      type == 'direct' ? (otherUser?.avatarUrl ?? '') : (avatarUrl ?? '');

  // Helper methods for type checking
  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';
  bool get isChannel => type == 'channel';
  bool get isMultiUser => isGroup || isChannel;
}
