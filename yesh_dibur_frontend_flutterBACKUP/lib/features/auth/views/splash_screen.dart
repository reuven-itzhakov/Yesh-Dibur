import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    
    // הפעלת בדיקת האותנטיקציה ברקע
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // נותנים לאנימציה לרוץ קצת כדי שהמעבר לא יהיה פתאומי מדי
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // אין משתמש מקומי בכלל
      context.go('/home');
      return;
    }

    try {
      // 1. כפיית רענון טוקן: זה תופס מצבים שבהם המשתמש נמחק ממסוף Firebase
      await user.getIdToken(true);

      // 2. בדיקה מול הבקאנד שלנו (PostgreSQL) שהפרופיל אכן קיים
      final authRepo = ref.read(authRepositoryProvider);
      final profile = await authRepo.getUserProfile();

      if (profile == null) {
        // המשתמש קיים בפיירבייס, אבל לא סיים הרשמה או נמחק מה-DB שלנו
        await FirebaseAuth.instance.signOut();
        if (mounted) context.go('/register');
      } else {
        // הכל תקין, המשתמש קיים בשתי המערכות
        if (mounted) context.go('/home');
      }
    } catch (e) {
      // אם הטוקן פג תוקף, נחסם, או שיש שגיאת רשת חמורה
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/register');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.gradientA,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'יש דיבור',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'העיר שלך. האנשים שלך.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}