import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/features/chats/data/repositories/conversation_repository_impl.dart';
import 'package:lockmess/features/chats/data/repositories/message_repository_impl.dart';
import 'package:lockmess/features/chats/domain/entities/conversation.dart';
import 'package:lockmess/features/chats/domain/entities/message.dart';

// Simple// Conversations provider
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((
  ref,
) async {
  final repo = ref.watch(conversationRepositoryProvider);
  return await repo.getConversations();
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

// Stream-based Conversations Provider - provides realtime updates for ALL conversations
final conversationsStreamProvider =
    StreamProvider.autoDispose<List<Conversation>>((ref) {
      final repo = ref.watch(conversationRepositoryProvider);
      return repo.streamConversations();
    });

// Filtered Stream Providers - filter from main stream data
final groupConversationsProvider =
    Provider.autoDispose<AsyncValue<List<Conversation>>>((ref) {
      final allConversations = ref.watch(conversationsStreamProvider);
      return allConversations.whenData(
        (list) => list.where((c) => c.isGroup).toList(),
      );
    });

final channelConversationsProvider =
    Provider.autoDispose<AsyncValue<List<Conversation>>>((ref) {
      final allConversations = ref.watch(conversationsStreamProvider);
      return allConversations.whenData(
        (list) => list.where((c) => c.isChannel).toList(),
      );
    });

// Hobbies Provider
final hobbiesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(conversationRepositoryProvider);
      return await repo.getAvailableHobbies();
    });

// Group/Channel Controller
final groupControllerProvider = Provider<GroupController>(
  (ref) => GroupController(ref),
);

class GroupController {
  final Ref ref;
  GroupController(this.ref);

  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      print('🟢 [GroupController] Creating group: $name');
      print('🟢 [GroupController] Members: ${memberIds.length}');

      final conversation = await ref
          .read(conversationRepositoryProvider)
          .createGroupConversation(name: name, memberIds: memberIds);

      print(
        '🟢 [GroupController] Group created successfully: ${conversation.id}',
      );

      ref.invalidate(conversationsProvider);
      ref.invalidate(groupConversationsProvider);
      return conversation;
    } catch (e, stackTrace) {
      print('🔴 [GroupController] Error creating group: $e');
      print('🔴 [GroupController] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Conversation> createChannel({
    required String name,
    String? description,
    List<String> hobbyIds = const [],
  }) async {
    try {
      print('🟣 [GroupController] Creating channel: $name');
      print('🟣 [GroupController] Description: $description');
      print('🟣 [GroupController] Hobbies: ${hobbyIds.length}');

      final conversation = await ref
          .read(conversationRepositoryProvider)
          .createChannel(
            name: name,
            description: description,
            hobbyIds: hobbyIds,
          );

      print(
        '🟣 [GroupController] Channel created successfully: ${conversation.id}',
      );

      ref.invalidate(conversationsProvider);
      ref.invalidate(channelConversationsProvider);
      return conversation;
    } catch (e, stackTrace) {
      print('🔴 [GroupController] Error creating channel: $e');
      print('🔴 [GroupController] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> joinChannel(String channelId) async {
    try {
      print('🟣 [GroupController] Joining channel: $channelId');
      await ref.read(conversationRepositoryProvider).joinChannel(channelId);

      print('🟣 [GroupController] Joined channel successfully');
      ref.invalidate(recommendedChannelsProvider);
      ref.invalidate(channelConversationsProvider);
      ref.invalidate(conversationsStreamProvider);
    } catch (e, stackTrace) {
      print('🔴 [GroupController] Error joining channel: $e');
      print('🔴 [GroupController] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

// Recommended Channels Provider
final recommendedChannelsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
      final repo = ref.watch(conversationRepositoryProvider);
      return await repo.getRecommendedChannels();
    });

// All Public Channels Provider (fallback when no hobbies match)
final allPublicChannelsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
      final repo = ref.watch(conversationRepositoryProvider);
      return await repo.getAllPublicChannels();
    });

// Channel Hobbies Provider
final channelHobbiesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, channelId) async {
      final repo = ref.watch(conversationRepositoryProvider);
      return await repo.getChannelHobbies(channelId);
    });
