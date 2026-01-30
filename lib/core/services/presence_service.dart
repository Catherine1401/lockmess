import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lockmess/core/network/supabase.dart';

/// Provider to track current user's presence (makes them appear online)
final presenceServiceProvider = Provider<PresenceService>((ref) {
  final client = ref.read(supabase).client;
  return PresenceService(client);
});

/// Provider to check if a specific user is online
final userPresenceProvider = StreamProvider.family<bool, String>((ref, userId) {
  final service = ref.read(presenceServiceProvider);
  return service.watchUserPresence(userId);
});

class PresenceService {
  final SupabaseClient _client;
  RealtimeChannel? _presenceChannel;
  final Set<String> _onlineUsers = {};

  PresenceService(this._client);

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Start tracking presence for current user
  Future<void> startTracking() async {
    if (currentUserId == null) return;

    _presenceChannel = _client.channel('presence:online');

    _presenceChannel!
        .onPresenceSync((payload) {
          _updateOnlineUsers();
        })
        .onPresenceJoin((payload) {
          _updateOnlineUsers();
        })
        .onPresenceLeave((payload) {
          _updateOnlineUsers();
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _presenceChannel!.track({
              'user_id': currentUserId,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });
  }

  void _updateOnlineUsers() {
    _onlineUsers.clear();
    final presences = _presenceChannel?.presenceState();
    if (presences != null) {
      for (final presence in presences) {
        // Each presence has a 'presences' list containing user data
        final userPresences = presence.presences;
        for (final p in userPresences) {
          final payload = p.payload;
          final userId = payload['user_id'] as String?;
          if (userId != null) {
            _onlineUsers.add(userId);
          }
        }
      }
    }
  }

  /// Check if a specific user is currently online
  bool isUserOnline(String userId) {
    return _onlineUsers.contains(userId);
  }

  /// Watch presence changes for a specific user
  Stream<bool> watchUserPresence(String userId) async* {
    // Initial state
    yield isUserOnline(userId);

    // Subscribe to presence channel if not already
    if (_presenceChannel == null) {
      await startTracking();
    }

    // Yield updates when presence changes
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      yield isUserOnline(userId);
    }
  }

  /// Stop tracking presence
  Future<void> stopTracking() async {
    await _presenceChannel?.untrack();
    await _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    _onlineUsers.clear();
  }
}
