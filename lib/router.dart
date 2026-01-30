import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/core/widgets/root_screen.dart';
import 'package:lockmess/features/friends/presentation/friend_screen.dart';
import 'package:lockmess/features/login/presentation/view/login_screen.dart';
import 'package:lockmess/features/profile/presentation/view/profile_screen.dart';
import 'package:lockmess/features/friends/presentation/view/search_friend_screen.dart';
import 'package:lockmess/features/friends/presentation/view/user_profile_screen.dart';
import 'package:lockmess/core/domain/entities/profile.dart';
import 'package:lockmess/features/chats/presentation/chats_screen.dart';
import 'package:lockmess/features/chats/presentation/groups_screen.dart';
import 'package:lockmess/features/chats/presentation/view/chat_screen.dart';
import 'package:lockmess/features/chats/presentation/view/create_group_screen.dart';
import 'package:lockmess/features/chats/presentation/view/create_channel_screen.dart';
import 'package:lockmess/features/profile/presentation/view/edit_profile_screen.dart';
import 'package:lockmess/features/chats/presentation/view/channel_profile_screen.dart';

final _chatNavigatorKey = GlobalKey<NavigatorState>();
final _groupNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  print('rebuld!!!!!');
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/chat',
    // refreshListenable: ValueNotifier(authState),
    routes: <RouteBase>[
      // login
      GoRoute(path: '/', builder: (_, _) => const LoginScreen()),

      // friends
      GoRoute(path: '/friend', builder: (_, _) => const FriendScreen()),
      GoRoute(
        path: '/search-friend',
        builder: (_, _) => const SearchFriendScreen(),
      ),
      GoRoute(
        path: '/user-profile',
        builder: (_, state) {
          final profile = state.extra as Profile;
          return UserProfileScreen(profile: profile);
        },
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/create-group',
        builder: (_, __) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/create-channel',
        builder: (_, __) => const CreateChannelScreen(),
      ),
      GoRoute(
        path: '/channel/:channelId',
        builder: (_, state) {
          final channelId = state.pathParameters['channelId']!;
          return ChannelProfileScreen(channelId: channelId);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, state) {
          final profile = state.extra as Profile;
          return EditProfileScreen(initialProfile: profile);
        },
      ),
      StatefulShellRoute.indexedStack(
        branches: <StatefulShellBranch>[
          // chat
          StatefulShellBranch(
            navigatorKey: _chatNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/chat', builder: (_, _) => const ChatsScreen()),
            ],
          ),

          // group
          StatefulShellBranch(
            navigatorKey: _groupNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/group', builder: (_, _) => const GroupsScreen()),
            ],
          ),

          // profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
        builder: (_, _, navigationShell) =>
            RootScreen(navigationShell: navigationShell),
      ),
    ],
    redirect: (_, state) {
      print('🔄 [Router] Navigating to: ${state.uri}');
      if (authState.value?.session == null) {
        print('🔄 [Router] No session, redirecting to /');
        return '/';
      }
      return null;
    },
  );
});
