import 'dart:async';
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
  Stream<List<Conversation>> streamConversations() {
    print('Starting conversation stream...');
    // Create a controller to manage the stream manually
    final controller = StreamController<List<Conversation>>();

    // 1. Fetch initial data immediately using the optimized View
    getConversations()
        .then((data) {
          if (!controller.isClosed) controller.add(data);
        })
        .catchError((e) {
          if (!controller.isClosed) controller.addError(e);
        });

    // 2. Setup Realtime subscription for relevant tables
    // We listen to 'conversations' (for reorder/updates) and 'conversation_participants' (for joins/leaves)
    // Note: listening to 'messages' is also an option but 'conversations' update trigger covers it (if trigger is installed)
    final channel = _supabase.client.channel('public:conversations_updates');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) async {
            print('Conversation update detected: ${payload.eventType}');
            // Refresh the list efficiently
            final data = await getConversations();
            if (!controller.isClosed) controller.add(data);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _myId,
          ),
          callback: (payload) async {
            print('Participant update detected: ${payload.eventType}');
            final data = await getConversations();
            if (!controller.isClosed) controller.add(data);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            print('New message detected - refreshing conversations');
            // Refresh conversations list when new message arrives
            final data = await getConversations();
            if (!controller.isClosed) controller.add(data);
          },
        )
        .subscribe();

    // Clean up on cancel
    controller.onCancel = () {
      print('Canceling conversation stream');
      _supabase.client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  @override
  Future<List<Conversation>> getConversations({
    int limit = 20,
    int offset = 0,
    String? type,
  }) async {
    try {
      print('🔵 [getConversations] Fetching for user: $_myId, type: $type');
      var query = _supabase.client
          .from('user_conversations_view')
          .select()
          .eq('owner_id', _myId);

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      print(
        '🔵 [getConversations] Got ${(response as List).length} conversations',
      );
      for (final conv in response) {
        print(
          '🔵 [getConversations] - ${conv['type']}: ${conv['name'] ?? conv['conversation_id']}',
        );
      }

      return (response as List).map((data) {
        Profile? otherUser;
        if (data['other_user_profile'] != null) {
          final profileData = data['other_user_profile'];
          otherUser = Profile(
            id: profileData['id'] ?? '',
            displayName: profileData['display_name'] ?? '',
            username: profileData['username'] ?? '',
            phone: profileData['phone'] ?? '',
            gender: profileData['gender'] ?? '',
            email: profileData['email'] ?? '',
            avatarUrl: profileData['avatar_url'] ?? '',
            birthday: profileData['birthday'] ?? '',
            hobbies: [], // Hobbies not included in list view for performance
          );
        }

        return Conversation(
          id: data['conversation_id'],
          type: data['type'],
          name: data['name'],
          avatarUrl: data['avatar_url'],
          lastMessageContent: data['last_message_content'],
          lastMessageTime: data['last_message_time'] != null
              ? DateTime.parse(data['last_message_time'])
              : null,
          unreadCount: data['unread_count'] as int,
          updatedAt: DateTime.parse(data['updated_at']),
          otherUser: otherUser,
        );
      }).toList();
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  @override
  Future<List<Conversation>> getConversationsByType(String type) async {
    try {
      final response = await _supabase.client
          .from('user_conversations_view')
          .select()
          .eq('owner_id', _myId)
          .eq('type', type)
          .order('last_message_time', ascending: false);

      return (response as List).map((data) {
        // ... (Similar mapping logic, simplified for brevity since it's identical mapping)
        // Actually, better to extract mapping or duplicate it safely.

        Profile? otherUser;
        if (data['other_user_profile'] != null) {
          final profileData = data['other_user_profile'];
          otherUser = Profile(
            id: profileData['id'] ?? '',
            displayName: profileData['display_name'] ?? '',
            username: profileData['username'] ?? '',
            phone: profileData['phone'] ?? '',
            gender: profileData['gender'] ?? '',
            email: profileData['email'] ?? '',
            avatarUrl: profileData['avatar_url'] ?? '',
            birthday: profileData['birthday'] ?? '',
            hobbies: [],
          );
        }

        return Conversation(
          id: data['conversation_id'],
          type: data['type'],
          name: data['name'],
          avatarUrl: data['avatar_url'],
          lastMessageContent: data['last_message_content'],
          lastMessageTime: data['last_message_time'] != null
              ? DateTime.parse(data['last_message_time'])
              : null,
          unreadCount: data['unread_count'] as int,
          updatedAt: DateTime.parse(data['updated_at']),
          otherUser: otherUser,
        );
      }).toList();
    } catch (e) {
      print('Error getting conversations by type: $e');
      return [];
    }
  }

  @override
  Future<Conversation> getConversationById(String conversationId) async {
    try {
      // Get conversation details
      final response = await _supabase.client
          .from('conversations')
          .select('id, type, name, description, avatar_url, updated_at')
          .eq('id', conversationId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Conversation not found');
      }

      // Get last message
      final lastMessageResponse = await _supabase.client
          .from('messages')
          .select('content, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Get unread count
      final participant = await _supabase.client
          .from('conversation_participants')
          .select('last_read_at')
          .eq('conversation_id', conversationId)
          .eq('user_id', _myId)
          .maybeSingle();

      final lastReadAt =
          participant != null && participant['last_read_at'] != null
          ? DateTime.parse(participant['last_read_at'])
          : null;

      int unreadCount = 0;
      if (lastReadAt != null) {
        final unreadMessages = await _supabase.client
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .gt('created_at', lastReadAt.toIso8601String())
            .neq('sender_id', _myId);
        unreadCount = unreadMessages.length;
      }

      // Handle different conversation types
      if (response['type'] == 'direct') {
        // Get other user's profile
        final participants = await _supabase.client
            .from('conversation_participants')
            .select('user_id, profiles!inner(*, hobbies(name))')
            .eq('conversation_id', conversationId)
            .neq('user_id', _myId);

        if (participants.isEmpty) {
          throw Exception('No other participant found');
        }

        final otherUserData = participants.first['profiles'];
        final hobbies = getHobbies([otherUserData]);
        final parsedUser = parseUser(otherUserData);

        final otherUser = Profile(
          id: parsedUser.id,
          displayName: parsedUser.displayName,
          username: parsedUser.username,
          phone: parsedUser.phone,
          gender: parsedUser.gender,
          email: parsedUser.email,
          avatarUrl: parsedUser.avatarUrl,
          birthday: parsedUser.birthday,
          hobbies: hobbies,
        );

        return Conversation(
          id: response['id'],
          type: response['type'],
          name: response['name'],
          avatarUrl: response['avatar_url'],
          lastMessageContent: lastMessageResponse?['content'],
          lastMessageTime: lastMessageResponse != null
              ? DateTime.parse(lastMessageResponse['created_at'])
              : null,
          unreadCount: unreadCount,
          updatedAt: DateTime.parse(response['updated_at']),
          otherUser: otherUser,
        );
      }

      // For group/channel conversations
      final memberList = await _supabase.client
          .from('conversation_participants')
          .select('user_id, profiles(avatar_url)')
          .eq('conversation_id', conversationId);

      List<String> recentAvatars = [];
      if (response['type'] == 'channel') {
        // Get up to 3 recent member avatars for visual indication
        final recentMembers = await _supabase.client
            .from('conversation_participants')
            .select('profiles(avatar_url)')
            .eq('conversation_id', conversationId)
            .order('joined_at', ascending: false)
            .limit(3);

        recentAvatars = (recentMembers as List)
            .map((m) => m['profiles']?['avatar_url'] as String?)
            .where((url) => url != null && url.isNotEmpty)
            .cast<String>()
            .toList();
      }

      return Conversation(
        id: response['id'],
        type: response['type'],
        name: response['name'],
        description: response['description'], // Add description
        avatarUrl: response['avatar_url'],
        lastMessageContent: lastMessageResponse?['content'],
        lastMessageTime: lastMessageResponse != null
            ? DateTime.parse(lastMessageResponse['created_at'])
            : null,
        unreadCount: unreadCount,
        updatedAt: DateTime.parse(response['updated_at']),
        memberIds: memberList.map((m) => m['user_id'] as String).toList(),
        memberCount: memberList.length,
        recentMemberAvatars: recentAvatars, // Add avatars
      );
    } catch (e) {
      print('Error getting conversation by id: $e');
      rethrow;
    }
  }

  @override
  Future<Conversation> getOrCreateDirectConversation(String friendId) async {
    try {
      print('Getting or creating conversation with friend: $friendId');

      // OPTIMIZED: Find existing direct conversation efficiently
      // Step 1: Get all direct conversation IDs where current user is a participant
      final myDirectConvs = await _supabase.client
          .from('conversation_participants')
          .select('conversation_id, conversations!inner(id, type)')
          .eq('user_id', _myId)
          .eq('conversations.type', 'direct');

      if (myDirectConvs.isNotEmpty) {
        // Step 2: Get the list of conversation IDs
        final convIds = myDirectConvs.map((c) => c['conversation_id']).toList();

        // Step 3: Check if friend is in any of these conversations (single query)
        final friendInConv = await _supabase.client
            .from('conversation_participants')
            .select('conversation_id')
            .eq('user_id', friendId)
            .inFilter('conversation_id', convIds)
            .limit(1)
            .maybeSingle();

        if (friendInConv != null) {
          final convId = friendInConv['conversation_id'];
          print('Found existing conversation (optimized): $convId');

          // Get conversation details
          final convData = await _supabase.client
              .from('conversations')
              .select('*')
              .eq('id', convId)
              .single();

          // Fetch friend profile for display
          final profileData = await _supabase.client
              .from('profiles')
              .select('*')
              .eq('id', friendId)
              .single();

          final user = parseUser(profileData);
          final otherUser = Profile(
            id: user.id,
            displayName: user.displayName,
            username: user.username,
            phone: user.phone,
            gender: user.gender,
            email: user.email,
            avatarUrl: user.avatarUrl,
            birthday: user.birthday,
            hobbies: [],
          );

          return Conversation(
            id: convId,
            type: 'direct',
            name: convData['name'],
            avatarUrl: convData['avatar_url'],
            unreadCount: 0,
            updatedAt: DateTime.parse(convData['updated_at']),
            otherUser: otherUser,
          );
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
          .select('*')
          .eq('id', friendId)
          .single();

      final user = parseUser(profileData);
      final otherUser = Profile(
        id: user.id,
        displayName: user.displayName,
        username: user.username,
        phone: user.phone,
        gender: user.gender,
        email: user.email,
        avatarUrl: user.avatarUrl,
        birthday: user.birthday,
        hobbies: [],
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

  @override
  Future<Conversation> createGroupConversation({
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      print('🟢 [Repository] Starting group creation');
      print('🟢 [Repository] Current user: $_myId');

      // Include current user in members
      final allMemberIds = {...memberIds, _myId}.toList();
      if (allMemberIds.length < 3) {
        throw Exception('A group must have at least 3 members (including you)');
      }
      print('🟢 [Repository] Total members: ${allMemberIds.length}');
      print('🟢 [Repository] Member IDs: $allMemberIds');

      // Create conversation
      print('🟢 [Repository] Creating conversation record...');
      final convResponse = await _supabase.client
          .from('conversations')
          .insert({'type': 'group', 'name': name, 'created_by': _myId})
          .select()
          .single();

      final conversationId = convResponse['id'];
      print('🟢 [Repository] Conversation created: $conversationId');

      // Add all members (creator is admin, others are members)
      final participants = allMemberIds.map((userId) {
        return {
          'conversation_id': conversationId,
          'user_id': userId,
          'role': userId == _myId ? 'admin' : 'member',
        };
      }).toList();

      print('🟢 [Repository] Adding ${participants.length} participants...');
      await _supabase.client
          .from('conversation_participants')
          .insert(participants);

      print('🟢 [Repository] Group creation completed successfully');

      return Conversation(
        id: conversationId,
        type: 'group',
        name: name,
        avatarUrl: convResponse['avatar_url'],
        unreadCount: 0,
        updatedAt: DateTime.parse(convResponse['updated_at']),
        memberCount: allMemberIds.length,
        memberIds: allMemberIds,
      );
    } catch (e, stackTrace) {
      print('🔴 [Repository] Error creating group: $e');
      print('🔴 [Repository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableHobbies() async {
    try {
      final data = await _supabase.client
          .from('hobbies')
          .select('id, name')
          .order('name');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching hobbies: $e');
      return [];
    }
  }

  @override
  Future<Conversation> createChannel({
    required String name,
    String? description,
    List<String> hobbyIds = const [],
  }) async {
    try {
      // Only creator is admin
      final allAdminIds = [_myId];

      // Create conversation
      final convResponse = await _supabase.client
          .from('conversations')
          .insert({
            'type': 'channel',
            'name': name,
            'description': description,
            'created_by': _myId,
          })
          .select()
          .single();

      final conversationId = convResponse['id'];

      // Add creator as admin
      await _supabase.client.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': _myId,
        'role': 'admin',
      });

      // Add hobbies if selected
      if (hobbyIds.isNotEmpty) {
        final hobbiesData = hobbyIds
            .map(
              (hobbyId) => {
                'conversation_id': conversationId,
                'hobby_id': hobbyId,
              },
            )
            .toList();

        await _supabase.client.from('conversation_hobbies').insert(hobbiesData);
      }

      return Conversation(
        id: conversationId,
        type: 'channel',
        name: name,
        avatarUrl: convResponse['avatar_url'],
        unreadCount: 0,
        updatedAt: DateTime.parse(convResponse['updated_at']),
        memberCount: 1,
        memberIds: allAdminIds,
      );
    } catch (e) {
      print('Error creating channel: $e');
      rethrow;
    }
  }

  @override
  Future<void> addMember(
    String conversationId,
    String userId, {
    String role = 'member',
  }) async {
    try {
      await _supabase.client.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': role,
      });
    } catch (e) {
      print('Error adding member: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeMember(String conversationId, String userId) async {
    try {
      await _supabase.client.from('conversation_participants').delete().match({
        'conversation_id': conversationId,
        'user_id': userId,
      });
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }

  @override
  Future<List<Conversation>> getRecommendedChannels() async {
    try {
      // 1. Get user's hobbies
      print('🔵 [Recommended] Fetching user hobbies for: $_myId');
      final userHobbiesResponse = await _supabase.client
          .from('profiles_hobbies')
          .select('hobby_id')
          .eq('user_id', _myId);

      final userHobbyIds = (userHobbiesResponse as List)
          .map((e) => e['hobby_id'].toString())
          .toSet();

      print('🔵 [Recommended] User hobbies: $userHobbyIds');

      if (userHobbyIds.isEmpty) {
        return []; // No hobbies = no matches
      }

      // 2. Get channels the user hasn't joined
      final myChannelIds = await _supabase.client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', _myId);

      final joinedIds = (myChannelIds as List)
          .map((c) => c['conversation_id'] as String)
          .toSet();

      // 3. Get all public channels with their hobbies
      // Note: This is not optimal for large datasets but works for <1000 channels.
      // Better approach would be filtering in SQL but requires complex join/subquery.
      final channelsResponse = await _supabase.client
          .from('conversations')
          .select('*, conversation_hobbies(hobby_id)')
          .eq('type', 'channel')
          .order('updated_at', ascending: false);

      final matchedChannels = (channelsResponse as List).where((channel) {
        // Exclude joined
        if (joinedIds.contains(channel['id'])) return false;

        // Check hobby overlap
        final channelHobbies = (channel['conversation_hobbies'] as List?)
            ?.map((h) => h['hobby_id'].toString())
            .toSet();

        if (channelHobbies == null || channelHobbies.isEmpty) return false;

        return channelHobbies.any((id) => userHobbyIds.contains(id));
      }).toList();

      return matchedChannels.map((data) {
        return Conversation(
          id: data['id'],
          type: 'channel',
          name: data['name'],
          avatarUrl: data['avatar_url'],
          unreadCount: 0,
          updatedAt: DateTime.parse(data['updated_at']),
          // We could map member_count and description if available in view or query
          description: data['description'],
        );
      }).toList();
    } catch (e) {
      print('Error getting recommended channels: $e');
      return [];
    }
  }

  @override
  Future<List<Conversation>> getAllPublicChannels() async {
    try {
      // Get all channels the user hasn't joined
      final myChannelIds = await _supabase.client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', _myId);

      final joinedIds = (myChannelIds as List)
          .map((c) => c['conversation_id'] as String)
          .toList();

      var query = _supabase.client
          .from('conversations')
          .select('*')
          .eq('type', 'channel');

      if (joinedIds.isNotEmpty) {
        // Use a negative filter approach
        final allChannels = await query.order('updated_at', ascending: false);

        return (allChannels as List)
            .where((c) => !joinedIds.contains(c['id']))
            .map((data) {
              return Conversation(
                id: data['id'],
                type: 'channel',
                name: data['name'],
                avatarUrl: data['avatar_url'],
                unreadCount: 0,
                updatedAt: DateTime.parse(data['updated_at']),
              );
            })
            .toList();
      }

      final channels = await query.order('updated_at', ascending: false);

      return (channels as List).map((data) {
        return Conversation(
          id: data['id'],
          type: 'channel',
          name: data['name'],
          avatarUrl: data['avatar_url'],
          unreadCount: 0,
          updatedAt: DateTime.parse(data['updated_at']),
        );
      }).toList();
    } catch (e) {
      print('Error getting all public channels: $e');
      return [];
    }
  }

  @override
  Future<void> joinChannel(String channelId) async {
    try {
      await _supabase.client.from('conversation_participants').insert({
        'conversation_id': channelId,
        'user_id': _myId,
        'role': 'member',
      });
    } catch (e) {
      print('Error joining channel: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveConversation(String conversationId) async {
    try {
      // 1. Check current role and member count
      final participants = await _supabase.client
          .from('conversation_participants')
          .select('user_id, role, joined_at')
          .eq('conversation_id', conversationId)
          .order('joined_at', ascending: true); // Oldest first

      final myParticipant = participants.firstWhere(
        (p) => p['user_id'] == _myId,
        orElse: () => throw Exception('Not a member of this conversation'),
      );

      final isOwner =
          myParticipant['role'] ==
          'admin'; // Assuming admin = owner for simplicity
      final memberCount = participants.length;

      if (isOwner) {
        if (memberCount == 1) {
          // Case 1: Owner matches only member -> Delete conversation
          print(
            '🔵 [Leave] Owner leaving as last member. Deleting conversation...',
          );
          // Delete request. Note: RLS might prevent this if not owner, but we checked role.
          // Deleting conversation should cascade delete participants/messages if FK set.
          await _supabase.client
              .from('conversations')
              .delete()
              .eq('id', conversationId);
          return;
        } else {
          // Case 2: Owner leaving, others remain -> Transfer ownership
          print('🔵 [Leave] Owner leaving. Transferring ownership...');

          // Find next oldest member who is NOT me
          final nextAdmin = participants.firstWhere(
            (p) => p['user_id'] != _myId,
          );

          final nextAdminId = nextAdmin['user_id'];
          print('🔵 [Leave] New admin will be: $nextAdminId');

          // Promote next member to admin
          await _supabase.client
              .from('conversation_participants')
              .update({'role': 'admin'})
              .eq('conversation_id', conversationId)
              .eq('user_id', nextAdminId);

          // Update conversation creator if we treat created_by as current owner
          // await _supabase.client.from('conversations').update({'created_by': nextAdminId}).eq('id', conversationId);
        }
      }

      // 3. Leave (Delete participant record)
      print('🔵 [Leave] Removing participant: $_myId');
      await _supabase.client
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', _myId);
    } catch (e) {
      print('Error leaving conversation: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getChannelHobbies(String channelId) async {
    try {
      final response = await _supabase.client
          .from('conversation_hobbies')
          .select('hobbies!inner(name)')
          .eq('conversation_id', channelId);

      return (response as List)
          .map((h) => h['hobbies']['name'] as String)
          .toList();
    } catch (e) {
      print('Error getting channel hobbies: $e');
      return [];
    }
  }
}
