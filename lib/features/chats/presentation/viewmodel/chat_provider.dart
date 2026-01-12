import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/features/chats/data/repositories/conversation_repository_impl.dart';
import 'package:lockmess/features/chats/data/repositories/message_repository_impl.dart';
import 'package:lockmess/features/chats/domain/entities/conversation.dart';
import 'package:lockmess/features/chats/domain/entities/message.dart';

// Simple Conversations Provider
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.getConversations(limit: 50);
});

// Single Conversation Provider
final conversationProvider = FutureProvider.autoDispose
    .family<Conversation?, String>((ref, conversationId) async {
      try {
        final repo = ref.watch(conversationRepositoryProvider);
        return await repo.getConversationById(conversationId);
      } catch (e) {
        print('Error fetching conversation: $e');
        return null;
      }
    });

// Messages Stream Provider
final messagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, conversationId) {
      final repo = ref.watch(messageRepositoryProvider);
      return repo.streamMessages(conversationId);
    });

// Chat Controller
final chatControllerProvider = Provider<ChatController>(
  (ref) => ChatController(ref),
);

class ChatController {
  final Ref ref;
  ChatController(this.ref);

  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      await ref
          .read(messageRepositoryProvider)
          .sendMessage(conversationId, content);
      ref.invalidate(conversationsProvider);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<Conversation> getOrCreateConversation(String friendId) async {
    try {
      final conv = await ref
          .read(conversationRepositoryProvider)
          .getOrCreateDirectConversation(friendId);
      ref.invalidate(conversationsProvider);
      return conv;
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await ref.read(conversationRepositoryProvider).markAsRead(conversationId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }
}
