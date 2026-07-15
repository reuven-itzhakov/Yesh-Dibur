import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/exceptions.dart';
import '../models/register_request.dart';
import '../providers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // השדות מאותחלים כעת ריקים (ללא נתוני דמה)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime? _selectedDate;
  
  final List<String> _availableInterests = [
    'פיתוח תוכנה', 'מציאות מדומה', 'טכנולוגיה', 'גיימינג', 
    'האקתונים בעפולה', 'ספורט', 'מוזיקה', 'טיולים'
  ];
  final List<String> _selectedInterests = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else if (_selectedInterests.length < 5) {
        _selectedInterests.add(interest);
      }
    });
  }

  void _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('חובה לבחור תאריך לידה')));
      return;
    }
    if (_selectedInterests.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('חובה לבחור בדיוק 5 תחומי עניין')));
      return;
    }

    final request = RegisterRequest(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      birthDate: _selectedDate!.toUtc().toIso8601String(), 
      interests: _selectedInterests,
    );

    final success = await ref.read(authControllerProvider.notifier).registerUser(
      password: _passwordController.text,
      request: request,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נרשמת בהצלחה!'), backgroundColor: Colors.green),
      );
      
      // ניווט אוטומטי למסך הבית (הפיד)
      context.go('/home'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            String message = error.toString();
            if (error is ServerException) message = error.message;
            if (error is ValidationException) message = 'שגיאת וולידציה:\n${error.errors}';
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
        );
      },
    );

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('הרשמה')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'אימייל')),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'סיסמה')),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'שם מלא (2-50 תווים)')),
            const SizedBox(height: 10),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'טלפון')),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _pickDate,
              child: Text(_selectedDate == null 
                  ? 'בחר תאריך לידה' 
                  : 'תאריך: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
            ),
            const SizedBox(height: 20),
            
            const Text('בחר 5 תחומי עניין:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (_) => _toggleInterest(interest),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: authState.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: authState.isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('הרשמה', style: TextStyle(fontSize: 18)),
            ),
            
            const SizedBox(height: 16),
            
            // כפתור המעבר למסך ההתחברות (Login)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('כבר יש לך חשבון? התחבר כאן'),
            ),
          ],
        ),
      ),
    );
  }
}