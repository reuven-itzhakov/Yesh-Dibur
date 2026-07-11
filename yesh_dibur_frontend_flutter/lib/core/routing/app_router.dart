import 'package:go_router/go_router.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/main_layout/views/main_layout_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MainLayoutScreen(),
    ),
  ],
);