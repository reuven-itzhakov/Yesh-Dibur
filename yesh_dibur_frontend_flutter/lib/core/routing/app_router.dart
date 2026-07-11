import 'package:go_router/go_router.dart';
import 'package:yesh_dibur_frontend_flutter/features/auth/views/register_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/auth_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/register', // שינינו זמנית כדי שתוכל לראות את המסך
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    // תחת ה-routes שלך:
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);