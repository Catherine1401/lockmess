import 'package:lockmess/features/chats/domain/entities/conversation.dart';

abstract class ConversationRepository {
  Stream<List<Conversation>> streamConversations();
  Future<List<Conversation>> getConversations({int limit = 20, int offset = 0});
  Future<Conversation?> getConversationById(String conversationId);
  Future<Conversation> getOrCreateDirectConversation(String friendId);
  Future<void> markAsRead(String conversationId);
}
