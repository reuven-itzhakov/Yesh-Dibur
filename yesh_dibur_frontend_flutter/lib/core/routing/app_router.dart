import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:yesh_dibur_frontend_flutter/features/auth/views/auth_screen.dart';
import 'package:yesh_dibur_frontend_flutter/features/chat/views/chat_screen.dart';
import 'package:yesh_dibur_frontend_flutter/features/groups/views/create_group_screen.dart';
import 'package:yesh_dibur_frontend_flutter/features/profile/views/profile_screen.dart';
import 'package:yesh_dibur_frontend_flutter/features/threads/views/create_thread_screen.dart';
import 'package:yesh_dibur_frontend_flutter/features/threads/views/thread_details_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/main_layout/views/main_layout_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // בדיקה ישירה מול פיירבייס האם קיים משתמש
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    
    // בדיקה האם הנתיב הנוכחי הוא אזור ציבורי (התחברות או הרשמה)
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    // אם לא מחובר ומנסה לגשת לאזור מוגן, זרוק להתחברות
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    
    // אם מחובר ומנסה לגשת למסכי אימות, זרוק לפיד הראשי
    if (isLoggedIn && isAuthRoute) {
      return '/';
    }

    return null; // המשך בניווט הרגיל
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const AuthScreen(),
    ),
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
    GoRoute(
      path: '/chat/:chatId/:receiverId/:receiverName', // עדכון נתיב הגישה
      name: 'chat-screen',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final receiverId = state.pathParameters['receiverId']!; // חילוץ המזהה
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