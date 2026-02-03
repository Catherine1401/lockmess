import 'package:lockmess/features/chats/domain/entities/message.dart';

abstract class MessageRepository {
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 30,
    int offset = 0,
  });
  Stream<List<Message>> streamMessages(String conversationId);
  Stream<Message> subscribeToNewMessages(String conversationId);
  Future<void> sendMessage(String conversationId, String content);
}
