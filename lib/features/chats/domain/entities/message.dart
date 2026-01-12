class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final String type; // 'text', 'image', 'file', etc.
  final DateTime createdAt;
  final bool isMine;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isMine,
  });
}
