import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/core/widgets/root_screen.dart';
import 'package:lockmess/features/friends/presentation/friend_screen.dart';
import 'package:lockmess/features/login/presentation/view/login_screen.dart';
import 'package:lockmess/features/profile/presentation/view/profile_screen.dart';
import 'package:lockmess/test.dart';

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
      StatefulShellRoute.indexedStack(
        branches: <StatefulShellBranch>[
          // chat
          StatefulShellBranch(
            navigatorKey: _chatNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/chat', builder: (_, _) => const Test()),
            ],
          ),

          // group
          StatefulShellBranch(
            navigatorKey: _groupNavigatorKey,
            routes: <RouteBase>[
              GoRoute(path: '/group', builder: (_, _) => Text('group')),
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
      print('hello wolrd');
      if (authState.value?.session == null) {
        return '/';
      }
      return null;
    },
  );
});
