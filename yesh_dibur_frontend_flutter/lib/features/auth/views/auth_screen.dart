import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/errors/exceptions.dart';
import '../providers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    
    if (email.isEmpty || password.isEmpty) return;
    
    // ניסיון התחברות
    // await ref.read(authControllerProvider.notifier).loginWithEmail(email, password);
  }

  @override
  Widget build(BuildContext context) {
    // האזנה לשגיאות מהקונטרולר והצגת חיווי מיידי למשתמש
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            final message = error is ServerException ? error.message : error.toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppTheme.destructive,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.gradientB, // שימוש בגרדיאנט B המשלב סגול ואקווה
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.electric_bolt_rounded,
                  size: 64,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'ברוכים הבאים',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'אימייל',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.mutedForeground),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'סיסמה',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.mutedForeground),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'התחברות',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}