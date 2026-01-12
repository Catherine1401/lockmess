import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/features/chats/domain/entities/message.dart';
import 'package:lockmess/features/chats/domain/repositories/message_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(ref.read(supabase));
});

final class MessageRepositoryImpl implements MessageRepository {
  final Supabase _supabase;

  MessageRepositoryImpl(this._supabase);

  String get _myId => _supabase.client.auth.currentUser!.id;

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _supabase.client
          .from('messages')
          .select('''
            id,
            conversation_id,
            sender_id,
            content,
            type,
            created_at,
            sender:profiles!sender_id(id, display_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);

      return (response as List).map((item) {
        final sender = item['sender'];
        return Message(
          id: item['id'],
          conversationId: item['conversation_id'],
          senderId: item['sender_id'],
          senderName: sender['display_name'] ?? 'Unknown',
          senderAvatar: sender['avatar_url'] ?? '',
          content: item['content'],
          type: item['type'],
          createdAt: DateTime.parse(item['created_at']),
          isMine: item['sender_id'] == _myId,
        );
      }).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  @override
  Stream<List<Message>> streamMessages(String conversationId) {
    return _supabase.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          // Fetch sender profiles for all messages
          final senderIds = data
              .map((item) => item['sender_id'] as String)
              .toSet();

          final profilesData = await _supabase.client
              .from('profiles')
              .select('id, display_name, avatar_url')
              .inFilter('id', senderIds.toList());

          final profilesMap = {for (var p in profilesData) p['id']: p};

          return data.map((item) {
            final profile = profilesMap[item['sender_id']];
            return Message(
              id: item['id'],
              conversationId: item['conversation_id'],
              senderId: item['sender_id'],
              senderName: profile?['display_name'] ?? 'Unknown',
              senderAvatar: profile?['avatar_url'] ?? '',
              content: item['content'],
              type: item['type'],
              createdAt: DateTime.parse(item['created_at']),
              isMine: item['sender_id'] == _myId,
            );
          }).toList();
        });
  }

  @override
  Future<void> sendMessage(String conversationId, String content) async {
    try {
      final now = DateTime.now();

      await _supabase.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _myId,
        'content': content,
        'type': 'text',
        'created_at': now.toIso8601String(),
      });

      // Immediately update conversation timestamp to ensure it appears at top
      await _supabase.client
          .from('conversations')
          .update({'updated_at': now.toIso8601String()})
          .eq('id', conversationId);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
