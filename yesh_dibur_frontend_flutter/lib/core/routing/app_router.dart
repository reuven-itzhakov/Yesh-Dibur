import 'package:go_router/go_router.dart';
import 'package:yesh_dibur_frontend_flutter/features/groups/views/create_group_screen.dart';
import 'package:yesh_dibur_frontend_flutter/features/threads/views/create_thread_screen.dart';
import 'package:yesh_dibur_frontend_flutter/features/threads/views/thread_details_screen.dart';
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
    GoRoute(
      path: '/create-group',
      name: 'create-group',
      builder: (context, state) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: '/create-thread',
      name: 'create-thread',
      builder: (context, state) => const CreateThreadScreen(),
    ),
    GoRoute(
      path: '/thread/:id',
      name: 'thread-details',
      builder: (context, state) {
        final threadId = state.pathParameters['id']!;
        return ThreadDetailsScreen(threadId: threadId);
      },
    ),
  ],
);