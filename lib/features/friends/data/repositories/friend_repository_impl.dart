import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/core/utils/get_user_info.dart';
import 'package:lockmess/features/friends/domain/entities/friend_request.dart';
import 'package:lockmess/features/friends/domain/repositories/friend_repository.dart';
import 'package:lockmess/core/domain/entities/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepositoryImpl(ref.read(supabase));
});

final class FriendRepositoryImpl with GetUserInfo implements FriendRepository {
  final Supabase _supabase;

  FriendRepositoryImpl(this._supabase);

  String get _myId => _supabase.client.auth.currentUser!.id;

  @override
  Future<List<Profile>> getFriends() async {
    try {
      final response = await _supabase.client
          .from('friendships')
          .select('''
        id,
        requester: profiles!requester_id(*, hobbies(name)),
        receiver: profiles!receiver_id(*, hobbies(name))
      ''')
          .eq('status', 'accepted')
          .or('requester_id.eq.$_myId,receiver_id.eq.$_myId');

      final List<Profile> friends = [];
      for (final item in response) {
        final requester = parseUser(item['requester']);
        final receiver = parseUser(item['receiver']);

        final friendData = item['requester']['id'] == _myId
            ? item['receiver']
            : item['requester'];

        // Parse hobbies correctly
        final hobbyList =
            (friendData['hobbies'] != null &&
                friendData['hobbies'] is List &&
                (friendData['hobbies'] as List).isNotEmpty)
            ? getHobbies([friendData])
            : <String>[];

        final user = item['requester']['id'] == _myId ? receiver : requester;

        friends.add(
          Profile(
            id: user.id,
            displayName: user.displayName,
            username: user.username,
            phone: user.phone,
            gender: user.gender,
            email: user.email,
            avatarUrl: user.avatarUrl,
            birthday: user.birthday,
            hobbies: hobbyList,
          ),
        );
      }
      return friends;
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  @override
  Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final response = await _supabase.client
          .from('friendships')
          .select('''
        id,
        created_at,
        sender: profiles!requester_id(id, display_name, avatar_url)
      ''')
          .eq('status', 'pending')
          .eq('receiver_id', _myId);

      return (response as List).map((item) {
        final sender = item['sender'];
        return FriendRequest(
          id: item['id'],
          senderId: sender['id'],
          senderName: sender['display_name'] ?? 'Unknown',
          senderAvatar: sender['avatar_url'] ?? '',
          status: 'pending',
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e) {
      print('Error getting requests: $e');
      return [];
    }
  }

  @override
  Future<String> getFriendStatus(String targetId) async {
    try {
      final response = await _supabase.client
          .from('friendships')
          .select()
          .or(
            'and(requester_id.eq.$_myId,receiver_id.eq.$targetId),and(requester_id.eq.$targetId,receiver_id.eq.$_myId)',
          )
          .maybeSingle();

      if (response == null) return 'none';

      final status = response['status'];
      final requesterId = response['requester_id'];

      if (status == 'accepted') return 'friend';
      if (status == 'pending') {
        return requesterId == _myId ? 'sent' : 'received';
      }
      return 'none';
    } catch (e) {
      print('Error getting status: $e');
      return 'none';
    }
  }

  @override
  Future<List<Profile>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      // Very basic search, ideally should exclude self and maybe friends
      final response = await _supabase.client
          .from('profiles')
          .select('*, hobbies(name)')
          .neq('id', _myId)
          .ilike('display_name', '%$query%');

      return (response as List).map((item) {
        final user = parseUser(item);
        final hobbies =
            (item['hobbies'] != null &&
                item['hobbies'] is List &&
                (item['hobbies'] as List).isNotEmpty)
            ? getHobbies([item])
            : <String>[];
        return Profile(
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
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  @override
  Future<void> sendFriendRequest(String targetId) async {
    await _supabase.client.from('friendships').insert({
      'requester_id': _myId,
      'receiver_id': targetId,
      'status': 'pending',
    });
  }

  @override
  Future<void> acceptFriendRequest(String senderId) async {
    await _supabase.client
        .from('friendships')
        .update({'status': 'accepted'})
        .match({'requester_id': senderId, 'receiver_id': _myId});
  }

  @override
  Future<void> declineFriendRequest(String senderId) async {
    await _supabase.client.from('friendships').delete().match({
      'requester_id': senderId,
      'receiver_id': _myId,
      'status': 'pending',
    });
  }

  @override
  Future<void> unfriend(String targetId) async {
    await _supabase.client
        .from('friendships')
        .delete()
        .or(
          'and(requester_id.eq.$_myId,receiver_id.eq.$targetId),and(requester_id.eq.$targetId,receiver_id.eq.$_myId)',
        );
  }

  @override
  Future<void> cancelFriendRequest(String targetId) async {
    await _supabase.client.from('friendships').delete().match({
      'requester_id': _myId,
      'receiver_id': targetId,
      'status': 'pending',
    });
  }
}
