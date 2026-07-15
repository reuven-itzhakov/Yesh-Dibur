import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AuthGuard {
  static bool check(BuildContext context, {required VoidCallback onProceed}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      onProceed();
      return true;
    } else {
      _showLoginSheet(context);
      return false;
    }
  }

  static void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppTheme.primary),
                const SizedBox(height: 16),
                const Text('התחברות נדרשת', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('כדי לבצע פעולה זו עליך להיות מחובר למערכת.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // סגירת החלון התחתון
                    context.push('/login'); // מעבר למסך ההתחברות
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: const Text('התחבר או הירשם'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ביטול', style: TextStyle(color: AppTheme.mutedForeground)),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}