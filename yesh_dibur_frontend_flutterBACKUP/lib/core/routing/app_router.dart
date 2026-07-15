import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/views/auth_screen.dart';
import '../../features/chat/views/chat_screen.dart';
import '../../features/groups/views/create_group_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/threads/views/create_thread_screen.dart';
import '../../features/threads/views/thread_details_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/main_layout/views/main_layout_screen.dart';
import '../../features/auth/views/registration_wizard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/', // המסך הראשון שיעלה הוא ה-Splash
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    // אם מחובר ומנסה לגשת למסכי התחברות, זרוק למסך הבית (הפיד)
    if (isLoggedIn && isAuthRoute) {
      return '/home';
    }

    // הגנה נוקשה רק על מסכים פנימיים מובהקים ברמת הראוטר (כמו הפרופיל האישי)
    final isStrictlyProtected = state.matchedLocation.startsWith('/profile');
    if (!isLoggedIn && isStrictlyProtected) {
      return '/login';
    }

    return null; // אורחים יכולים להישאר ב-/home (הפיד) באופן חופשי
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegistrationWizardScreen(), // הקובץ החדש שיצרנו
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
    GoRoute(
      path: '/chat/:chatId/:receiverId/:receiverName',
      name: 'chat-screen',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final receiverId = state.pathParameters['receiverId']!;
        final receiverName = state.pathParameters['receiverName']!;
        return ChatScreen(
          chatId: chatId, 
          receiverId: receiverId, 
          receiverName: receiverName,
        );
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);