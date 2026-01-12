import 'package:lockmess/features/chats/domain/entities/message.dart';

abstract class MessageRepository {
  Future<List<Message>> getMessages(String conversationId);
  Stream<List<Message>> streamMessages(String conversationId);
  Future<void> sendMessage(String conversationId, String content);
}
