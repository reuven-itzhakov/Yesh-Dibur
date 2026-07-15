import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yesh_dibur_frontend_flutter/shared/widgets/main_scaffold.dart';

// מפתחות גלובליים לניהול מצב הניווט
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// חושפים את הראוטר לכל האפליקציה דרך Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  
  // בעתיד נירשם כאן למצב המשתמש (authProvider) כדי שנוכל
  // לרענן את הראוטר אוטומטית כשהמשתמש מתחבר או מתנתק
  // final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/', // מסך הנחיתה שלנו (פיד הגילוי)
    
    // ניהול שגיאות ניווט (למשל אם מנסים לגשת לנתיב שלא קיים)
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('המסך לא נמצא: ${state.error}')),
    ),
    
    routes: [
      // ShellRoute מאפשר לנו לעטוף מספר מסכים עם ממשק משותף (כמו סרגל תחתון)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // כאן בהמשך נחזיר את ה-MainScaffold שניצור בתיקיית shared,
          // אשר יכיל את ה-BottomNavigationBar ויציג את המסכים (child) בתוכו.
          return MainScaffold(child: child);
        },
        routes: [
          // טאב 1: מסך הבית (פיד גילוי וקבוצות)
          GoRoute(
            path: '/',
            builder: (context, state) => const Center(child: Text('מסך הבית (פיד)')),
          ),
          // טאב 2: חיפוש
          GoRoute(
            path: '/search',
            builder: (context, state) => const Center(child: Text('מסך חיפוש')),
          ),
          // טאב 3: התראות
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const Center(child: Text('מסך התראות')),
          ),
          // טאב 4: צ'אט (Inbox)
          GoRoute(
            path: '/chat',
            builder: (context, state) => const Center(child: Text('מסך תיבות שיחה')),
          ),
        ],
      ),
      
      // מסכים שלא צריכים את סרגל הניווט התחתון יוגדרו מחוץ ל-ShellRoute
      // לדוגמה, מסכי הרשמה ופרופיל פנימי
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Center(child: Text('מסך פרופיל והגדרות')),
      ),
    ],
    
    // מנגנון ה-Redirect (שומר הסף שלנו)
    redirect: (context, state) {
      // כאן נממש את הלוגיקה החוסמת אורחים לפי האפיון
      // לדוגמה, אם המשתמש הוא אורח והוא מנסה לגשת ל- /chat דרך דיפ-לינק, 
      // נחסום אותו ונחזיר אותו ל- / או שנקפיץ לו את מסך ההתחברות.
      return null; // כרגע מאפשרים להכל לעבור
    },
  );
});