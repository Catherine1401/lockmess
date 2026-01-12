import 'package:lockmess/core/domain/entities/profile.dart';

class Conversation {
  final String id;
  final String type; // 'direct' or 'group'
  final String? name;
  final String? avatarUrl;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime updatedAt;
  final Profile? otherUser; // For direct chats

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
  });

  String get displayName => type == 'direct'
      ? (otherUser?.displayName ?? 'Unknown')
      : (name ?? 'Group');

  String get displayAvatar =>
      type == 'direct' ? (otherUser?.avatarUrl ?? '') : (avatarUrl ?? '');
}
