import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(routes: <RouteBase>[
  GoRoute(path: '/', builder: (_, _) => const LoginScreen()),
]);
