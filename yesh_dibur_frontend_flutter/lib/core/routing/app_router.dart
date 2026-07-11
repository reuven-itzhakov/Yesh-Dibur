import 'package:go_router/go_router.dart';
import '../../features/auth/views/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    // נכניס לכאן את נתיבי ה-auth וה-home בשלבים הבאים
  ],
);