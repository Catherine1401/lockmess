import 'package:go_router/go_router.dart';
import 'package:lockmess/features/presentation/view/login_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (_, _) => const LoginScreen()),
  ],
);

