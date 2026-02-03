import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/features/chats/data/repositories/conversation_repository_impl.dart';
import 'package:lockmess/features/chats/data/repositories/message_repository_impl.dart';
import 'package:lockmess/features/chats/domain/entities/conversation.dart';
import 'package:lockmess/features/chats/domain/entities/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Pagination State
class PaginatedConversationsState {
  final List<Conversation> conversations;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PaginatedConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PaginatedConversationsState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PaginatedConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

// Pagination Map Notifier
class PaginatedConversationsMapNotifier
    extends Notifier<Map<String, PaginatedConversationsState>> {
  static const int _pageSize = 20;
  bool _mounted = true;
  RealtimeChannel? _messagesChannel;

  @override
  Map<String, PaginatedConversationsState> build() {
    _mounted = true;
    _setupRealtimeSubscription();
    ref.onDispose(() {
      _mounted = false;
      _removeRealtimeSubscription();
    });
    return {};
  }

  void _setupRealtimeSubscription() {
    final supabaseInstance = ref.read(supabase);
    _messagesChannel = supabaseInstance.client.channel(
      'paginated_conversations_messages',
    );
    _messagesChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            print(
              '🔄 [PaginatedConversations] New message detected, refreshing...',
            );
            // Refresh all conversation types that are loaded
            for (final type in state.keys) {
              refresh(type);
            }
          },
        )
        .subscribe();
  }

  void _removeRealtimeSubscription() {
    if (_messagesChannel != null) {
      ref.read(supabase).client.removeChannel(_messagesChannel!);
      _messagesChannel = null;
    }
  }

  // Called by UI to ensure data is loaded
  void init(String type) {
    if (!state.containsKey(type)) {
      Future.microtask(() => loadInitial(type));
    }
  }

  Future<void> loadInitial(String type) async {
    if (!_mounted) return;

    // Set loading state if not present or to update UI
    state = {
      ...state,
      type: (state[type] ?? const PaginatedConversationsState()).copyWith(
        isLoading: true,
      ),
    };

    try {
      final repo = ref.read(conversationRepositoryProvider);
      final conversations = await repo.getConversations(
        limit: _pageSize,
        offset: 0,
        type: type,
      );

      if (!_mounted) return;

      state = {
        ...state,
        type: PaginatedConversationsState(
          conversations: conversations,
          isLoading: false,
          hasMore: conversations.length >= _pageSize,
          currentPage: 1,
        ),
      };
    } catch (e) {
      if (!_mounted) return;
      state = {
        ...state,
        type: (state[type] ?? const PaginatedConversationsState()).copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  Future<void> loadMore(String type) async {
    if (!_mounted) return;
    final currentState = state[type];
    if (currentState == null) return;

    print(
      '📦 [Pagination($type)] loadMore called. isLoading: ${currentState.isLoading}, hasMore: ${currentState.hasMore}',
    );
    if (currentState.isLoading || !currentState.hasMore) return;

    state = {...state, type: currentState.copyWith(isLoading: true)};

    try {
      final repo = ref.read(conversationRepositoryProvider);
      final offset = currentState.currentPage * _pageSize;
      print('📦 [Pagination($type)] Fetching offset: $offset');
      final newConversations = await repo.getConversations(
        limit: _pageSize,
        offset: offset,
        type: type,
      );

      if (!_mounted) return;

      final nextState = currentState.copyWith(
        conversations: [...currentState.conversations, ...newConversations],
        isLoading: false,
        hasMore: newConversations.length >= _pageSize,
        currentPage: currentState.currentPage + 1,
      );

      state = {...state, type: nextState};

      print(
        '📦 [Pagination($type)] Loaded ${newConversations.length} more, total: ${nextState.conversations.length}',
      );
    } catch (e) {
      print('🔴 [Pagination($type)] Error: $e');
      if (!_mounted) return;
      state = {
        ...state,
        type: currentState.copyWith(isLoading: false, error: e.toString()),
      };
    }
  }

  Future<void> refresh(String type) async {
    if (!_mounted) return;
    state = {
      ...state,
      type: const PaginatedConversationsState(isLoading: true),
    };
    await loadInitial(type);
  }
}

// Provider for paginated conversations map
final paginatedConversationsMapProvider =
    NotifierProvider.autoDispose<
      PaginatedConversationsMapNotifier,
      Map<String, PaginatedConversationsState>
    >(PaginatedConversationsMapNotifier.new);

// Paginated Messages State
class PaginatedMessagesState {
  final List<Message> messages;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginatedMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedMessagesState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// Map of conversationId -> PaginatedMessagesNotifier
final paginatedMessagesProvider = StateNotifierProvider.family
    .autoDispose<PaginatedMessagesNotifier, PaginatedMessagesState, String>((
      ref,
      conversationId,
    ) {
      return PaginatedMessagesNotifier(ref, conversationId);
    });

class PaginatedMessagesNotifier extends StateNotifier<PaginatedMessagesState> {
  final Ref _ref;
  final String _conversationId;
  StreamSubscription? _subscription;
  static const int _pageSize = 30;
  bool _isInit = false;

  PaginatedMessagesNotifier(this._ref, this._conversationId)
    : super(const PaginatedMessagesState());

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadInitial() async {
    if (_isInit) return;
    _isInit = true;

    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(messageRepositoryProvider);

      // 1. Fetch initial batch (newest first)
      final messages = await repo.getMessages(
        _conversationId,
        limit: _pageSize,
        offset: 0,
      );

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMore: messages.length >= _pageSize,
      );

      // 2. Subscribe to realtime updates
      _subscribe();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(messageRepositoryProvider);
      final currentLength = state.messages.length;

      final moreMessages = await repo.getMessages(
        _conversationId,
        limit: _pageSize,
        offset: currentLength,
      );

      state = state.copyWith(
        messages: [
          ...state.messages,
          ...moreMessages,
        ], // Append to end (since list is reversed in UI)
        isLoading: false,
        hasMore: moreMessages.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribe() {
    // Assuming subscribeToNewMessages is available on the implementation
    final repo = _ref.read(messageRepositoryProvider) as dynamic;

    _subscription = repo.subscribeToNewMessages(_conversationId).listen((
      newMessage,
    ) {
      // Prepend new message (index 0 for reversed list)
      // Check for duplicates
      if (state.messages.any((m) => m.id == newMessage.id)) return;

      state = state.copyWith(messages: [newMessage, ...state.messages]);
    });
  }
}

// Simple Conversations provider
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

      // Refresh direct chats list
      ref.read(paginatedConversationsMapProvider.notifier).refresh('direct');
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
      // Refresh conversation lists to update unread count in UI
      final notifier = ref.read(paginatedConversationsMapProvider.notifier);
      for (final type in ['direct', 'group', 'channel']) {
        notifier.refresh(type);
      }
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
      return allConversations.whenData((list) {
        final groups = list.where((c) => c.isGroup).toList();
        print(
          '🟣 [groupConversationsProvider] Total: ${list.length}, Groups: ${groups.length}',
        );
        for (final g in groups) {
          print('🟣 [groupConversationsProvider] - ${g.name}');
        }
        return groups;
      });
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
      ref.invalidate(conversationsStreamProvider);
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

      // Refresh channels list
      ref.read(paginatedConversationsMapProvider.notifier).refresh('channel');

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

      // Refresh channels list
      ref.read(paginatedConversationsMapProvider.notifier).refresh('channel');

      // Invalidate recommendations so channel is removed from discover list
      ref.invalidate(recommendedChannelsProvider);
      ref.invalidate(allPublicChannelsProvider);

      // Keep legacy invalidation if other widgets use it
      ref.invalidate(channelConversationsProvider);
      ref.invalidate(conversationsStreamProvider);
    } catch (e, stackTrace) {
      print('🔴 [GroupController] Error joining channel: $e');
      print('🔴 [GroupController] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    try {
      print('🟣 [GroupController] Leaving conversation: $conversationId');
      await ref
          .read(conversationRepositoryProvider)
          .leaveConversation(conversationId);

      print('🟣 [GroupController] Left conversation successfully');

      // Refresh lists
      ref.invalidate(conversationsProvider);
      ref.invalidate(conversationsStreamProvider);
      ref.invalidate(groupConversationsProvider);
      ref.invalidate(channelConversationsProvider);
      ref.read(paginatedConversationsMapProvider.notifier).refresh('channel');
      ref.read(paginatedConversationsMapProvider.notifier).refresh('group');
    } catch (e) {
      print('🔴 [GroupController] Error leaving conversation: $e');
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
