import 'package:lockmess/features/chats/domain/entities/conversation.dart';

abstract class ConversationRepository {
  Future<List<Conversation>> getConversations({
    int limit = 20,
    int offset = 0,
    String? type,
  });
  Future<Conversation> getConversationById(String conversationId);
  Future<Conversation> getOrCreateDirectConversation(String otherUserId);
  Future<void> markAsRead(String conversationId);
  Stream<List<Conversation>> streamConversations();

  // Group and Channel operations
  Future<Conversation> createGroupConversation({
    required String name,
    required List<String> memberIds,
  });

  Future<Conversation> createChannel({
    required String name,
    String? description,
    List<String> hobbyIds = const [],
  });

  Future<List<Map<String, dynamic>>> getAvailableHobbies();

  Future<List<Conversation>> getConversationsByType(String type);

  Future<void> addMember(
    String conversationId,
    String userId, {
    String role = 'member',
  });

  Future<void> removeMember(String conversationId, String userId);

  // Channel Discovery
  Future<List<Conversation>> getRecommendedChannels();
  Future<List<Conversation>> getAllPublicChannels();
  Future<void> joinChannel(String channelId);
  Future<void> leaveConversation(String conversationId);
  Future<List<String>> getChannelHobbies(String channelId);
}
