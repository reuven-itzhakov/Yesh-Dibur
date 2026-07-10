import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';

// חייבים StatefulWidget כדי לנהל את ה-Controllers של שדות הטקסט
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers לקריאת הנתונים שהמשתמש מקליד
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime? _selectedBirthDate;
  List<String> _selectedInterests = []; // במציאות ינוהל דרך מסך בחירה או צ'יפים

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // פונקציית השליחה שמוודאת שהטופס תקין לפני הפנייה לשרת
  void _submitRegistration() {
    // 1. וולידציה של שדות הטקסט
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    // 2. וולידציה של נתונים מורכבים (תאריך ותחומי עניין)
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('חובה לבחור תאריך לידה')));
      return;
    }
    
    // בדיוק כפי שהוגדר ב-backend באפיון
    if (_selectedInterests.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('יש לבחור בדיוק 5 תחומי עניין')));
      return;
    }

    // 3. שליחה מסודרת לקונטרולר עם הנתונים האמיתיים
    ref.read(authControllerProvider.notifier).register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      birthDate: _selectedBirthDate!.toIso8601String(),
      interests: _selectedInterests,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message)));
      } else if (next is AuthSuccess) {
        // נווט למסך הבא (למשל פיד הגילוי)
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('יצירת חשבון')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'שם מלא'),
                validator: (value) => value == null || value.isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'אימייל'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@') ? 'אימייל לא תקין' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'סיסמה'),
                obscureText: true,
                validator: (value) => value != null && value.length < 6 ? 'סיסמה קצרה מדי' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'מספר טלפון'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              // כפתור ההרשמה - מציג לואודינג רק כשהבקשה באוויר
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authState is AuthLoading ? null : _submitRegistration,
                  child: authState is AuthLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('הרשמה לאפליקציה'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}