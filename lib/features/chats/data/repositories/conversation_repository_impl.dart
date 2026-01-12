import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/domain/entities/profile.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/core/utils/get_user_info.dart';
import 'package:lockmess/features/chats/domain/entities/conversation.dart';
import 'package:lockmess/features/chats/domain/repositories/conversation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(ref.read(supabase));
});

final class ConversationRepositoryImpl
    with GetUserInfo
    implements ConversationRepository {
  final Supabase _supabase;

  ConversationRepositoryImpl(this._supabase);

  String get _myId => _supabase.client.auth.currentUser!.id;

  @override
  Stream<List<Conversation>> streamConversations() async* {
    try {
      print('Starting conversation stream...');

      // Stream conversation_participants realtime
      await for (final participantsData
          in _supabase.client
              .from('conversation_participants')
              .stream(primaryKey: ['id'])
              .eq('user_id', _myId)
              .limit(20)) {
        print('Received ${participantsData.length} participants');
        final conversations = <Conversation>[];

        // Process conversations progressively
        for (final item in participantsData) {
          try {
            // Get conversation details
            final convResponse = await _supabase.client
                .from('conversations')
                .select('id, type, name, avatar_url, updated_at')
                .eq('id', item['conversation_id'])
                .maybeSingle();

            if (convResponse == null) continue;

            final conv = convResponse;
            final conversationId = conv['id'];

            // Get last message (async but quick)
            final lastMessageData = await _supabase.client
                .from('messages')
                .select('content, created_at')
                .eq('conversation_id', conversationId)
                .isFilter('deleted_at', null)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            // Calculate unread count
            final lastReadAt = item['last_read_at'];
            final unreadResponse = await _supabase.client
                .from('messages')
                .select('id')
                .eq('conversation_id', conversationId)
                .neq('sender_id', _myId)
                .isFilter('deleted_at', null)
                .gt('created_at', lastReadAt ?? '1970-01-01');

            final unreadCount = (unreadResponse as List).length;

            Profile? otherUser;

            // For direct chats, get other user
            if (conv['type'] == 'direct') {
              final participants = await _supabase.client
                  .from('conversation_participants')
                  .select('user_id, profiles!inner(*, hobbies(name))')
                  .eq('conversation_id', conversationId)
                  .neq('user_id', _myId)
                  .maybeSingle();

              if (participants != null) {
                final profileData = participants['profiles'];
                final user = parseUser(profileData);
                final hobbies =
                    (profileData['hobbies'] != null &&
                        profileData['hobbies'] is List &&
                        (profileData['hobbies'] as List).isNotEmpty)
                    ? getHobbies([profileData])
                    : <String>[];

                otherUser = Profile(
                  id: user.id,
                  displayName: user.displayName,
                  username: user.username,
                  phone: user.phone,
                  gender: user.gender,
                  email: user.email,
                  avatarUrl: user.avatarUrl,
                  birthday: user.birthday,
                  hobbies: hobbies,
                );
              }
            }

            conversations.add(
              Conversation(
                id: conversationId,
                type: conv['type'],
                name: conv['name'],
                avatarUrl: conv['avatar_url'],
                lastMessageContent: lastMessageData?['content'],
                lastMessageTime: lastMessageData != null
                    ? DateTime.parse(lastMessageData['created_at'])
                    : null,
                unreadCount: unreadCount,
                updatedAt: DateTime.parse(conv['updated_at']),
                otherUser: otherUser,
              ),
            );
          } catch (e) {
            print('Error processing conversation: $e');
            continue;
          }
        }

        // Sort by updated_at descending
        conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        print('Yielding ${conversations.length} conversations');
        // Emit current list (progressive + realtime)
        yield conversations;
      }
    } catch (e) {
      print('Error streaming conversations: $e');
      yield [];
    }
  }

  @override
  Future<List<Conversation>> getConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Get conversations where user is a participant
      final response = await _supabase.client
          .from('conversation_participants')
          .select('''
            conversation_id,
            last_read_at,
            conversations!inner(
              id,
              type,
              name,
              avatar_url,
              updated_at
            )
          ''')
          .eq('user_id', _myId)
          .order('conversations(updated_at)', ascending: false)
          .range(offset, offset + limit - 1);

      final conversations = <Conversation>[];

      for (final item in response) {
        final conv = item['conversations'];
        final conversationId = conv['id'];

        // Get last message
        final lastMessageData = await _supabase.client
            .from('messages')
            .select('content, created_at')
            .eq('conversation_id', conversationId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        // Get unread count
        final lastReadAt = item['last_read_at'];
        final unreadResponse = await _supabase.client
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .neq('sender_id', _myId)
            .isFilter('deleted_at', null)
            .gt('created_at', lastReadAt ?? '1970-01-01');

        final unreadCount = (unreadResponse as List).length;

        Profile? otherUser;

        // For direct chats, get the other user's profile
        if (conv['type'] == 'direct') {
          final participants = await _supabase.client
              .from('conversation_participants')
              .select('user_id, profiles!inner(*, hobbies(name))')
              .eq('conversation_id', conversationId)
              .neq('user_id', _myId)
              .maybeSingle();

          if (participants != null) {
            final profileData = participants['profiles'];
            final user = parseUser(profileData);
            final hobbies =
                (profileData['hobbies'] != null &&
                    profileData['hobbies'] is List &&
                    (profileData['hobbies'] as List).isNotEmpty)
                ? getHobbies([profileData])
                : <String>[];

            otherUser = Profile(
              id: user.id,
              displayName: user.displayName,
              username: user.username,
              phone: user.phone,
              gender: user.gender,
              email: user.email,
              avatarUrl: user.avatarUrl,
              birthday: user.birthday,
              hobbies: hobbies,
            );
          }
        }

        conversations.add(
          Conversation(
            id: conversationId,
            type: conv['type'],
            name: conv['name'],
            avatarUrl: conv['avatar_url'],
            lastMessageContent: lastMessageData?['content'],
            lastMessageTime: lastMessageData != null
                ? DateTime.parse(lastMessageData['created_at'])
                : null,
            unreadCount: unreadCount,
            updatedAt: DateTime.parse(conv['updated_at']),
            otherUser: otherUser,
          ),
        );
      }

      return conversations;
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  @override
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      // Fetch conversation details
      final convData = await _supabase.client
          .from('conversations')
          .select('id, type, name, avatar_url, updated_at')
          .eq('id', conversationId)
          .maybeSingle();

      if (convData == null) return null;

      Profile? otherUser;

      // For direct chats, get other user's profile
      if (convData['type'] == 'direct') {
        final participants = await _supabase.client
            .from('conversation_participants')
            .select('user_id, profiles!inner(*, hobbies(name))')
            .eq('conversation_id', conversationId)
            .neq('user_id', _myId)
            .maybeSingle();

        if (participants != null) {
          final profileData = participants['profiles'];
          final user = parseUser(profileData);
          final hobbies =
              (profileData['hobbies'] != null &&
                  profileData['hobbies'] is List &&
                  (profileData['hobbies'] as List).isNotEmpty)
              ? getHobbies([profileData])
              : <String>[];

          otherUser = Profile(
            id: user.id,
            displayName: user.displayName,
            username: user.username,
            phone: user.phone,
            gender: user.gender,
            email: user.email,
            avatarUrl: user.avatarUrl,
            birthday: user.birthday,
            hobbies: hobbies,
          );
        }
      }

      return Conversation(
        id: convData['id'],
        type: convData['type'],
        name: convData['name'],
        avatarUrl: convData['avatar_url'],
        unreadCount: 0,
        updatedAt: DateTime.parse(convData['updated_at']),
        otherUser: otherUser,
      );
    } catch (e) {
      print('Error getting conversation by ID: $e');
      return null;
    }
  }

  @override
  Future<Conversation> getOrCreateDirectConversation(String friendId) async {
    try {
      print('Getting or creating conversation with friend: $friendId');

      // Check if conversation already exists by checking participants
      final existingParticipants = await _supabase.client
          .from('conversation_participants')
          .select('conversation_id, conversations!inner(id, type)')
          .eq('user_id', _myId);

      print(
        'Found ${existingParticipants.length} existing participants for current user',
      );

      // Look for a direct conversation where both users are participants
      for (final participant in existingParticipants) {
        final convId = participant['conversation_id'];
        final conv = participant['conversations'];

        if (conv['type'] != 'direct') continue;

        // Check if friend is also a participant
        final friendParticipant = await _supabase.client
            .from('conversation_participants')
            .select('id')
            .eq('conversation_id', convId)
            .eq('user_id', friendId)
            .maybeSingle();

        if (friendParticipant != null) {
          print('Found existing conversation: $convId');
          // Fetch full conversation details
          final existing = await getConversationById(convId);
          if (existing == null) {
            throw Exception('Conversation not found');
          }
          return existing;
        }
      }

      print('No existing conversation found, creating new one');

      // Create new conversation
      final newConv = await _supabase.client
          .from('conversations')
          .insert({'type': 'direct', 'created_by': _myId})
          .select()
          .single();

      print('Created conversation: ${newConv['id']}');

      // Add both participants
      await _supabase.client.from('conversation_participants').insert([
        {'conversation_id': newConv['id'], 'user_id': _myId},
        {'conversation_id': newConv['id'], 'user_id': friendId},
      ]);

      print('Added participants');

      // Fetch friend profile
      final profileData = await _supabase.client
          .from('profiles')
          .select('*, hobbies(name)')
          .eq('id', friendId)
          .single();

      final user = parseUser(profileData);
      final hobbies =
          (profileData['hobbies'] != null &&
              profileData['hobbies'] is List &&
              (profileData['hobbies'] as List).isNotEmpty)
          ? getHobbies([profileData])
          : <String>[];

      final otherUser = Profile(
        id: user.id,
        displayName: user.displayName,
        username: user.username,
        phone: user.phone,
        gender: user.gender,
        email: user.email,
        avatarUrl: user.avatarUrl,
        birthday: user.birthday,
        hobbies: hobbies,
      );

      final result = Conversation(
        id: newConv['id'],
        type: newConv['type'],
        name: newConv['name'],
        avatarUrl: newConv['avatar_url'],
        unreadCount: 0,
        updatedAt: DateTime.parse(newConv['updated_at']),
        otherUser: otherUser,
      );

      print('Returning conversation: ${result.id}');
      return result;
    } catch (e, stackTrace) {
      print('Error creating conversation: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    try {
      await _supabase.client
          .from('conversation_participants')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .match({'conversation_id': conversationId, 'user_id': _myId});
    } catch (e) {
      print('Error marking as read: $e');
    }
  }
}
