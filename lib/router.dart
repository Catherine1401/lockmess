import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lockmess/core/network/supabase.dart';
import 'package:lockmess/core/widgets/root_screen.dart';
import 'package:lockmess/features/login/presentation/view/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabase).client.auth.onAuthStateChange;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: ValueNotifier(authState),
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => const RootScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    ],
    redirect: (_, state) {
      if (authState.value?.event == AuthChangeEvent.initialSession) return '/';
      return null;
    },
  );
});
