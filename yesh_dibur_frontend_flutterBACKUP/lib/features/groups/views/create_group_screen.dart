import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/exceptions.dart';
import '../models/create_group_request.dart';
import '../providers/group_controller.dart';
// יש לייבא גם את פיד הפרובידר כדי לרענן אותו אחרי היצירה
import '../../feed/providers/feed_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  final List<String> _availableInterests = [
    'פיתוח תוכנה', 'מציאות מדומה', 'גיימינג', 'האקתונים', 'סטודנטים', 'מוזיקה', 'טיולים'
  ];
  final List<String> _selectedInterests = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
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
    if (_nameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שם קבוצה חייב להכיל לפחות 2 תווים')));
      return;
    }
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('חובה לבחור לפחות תחום עניין אחד')));
      return;
    }

    final request = CreateGroupRequest(
      name: _nameController.text,
      description: _descController.text,
      interests: _selectedInterests,
    );

    final success = await ref.read(groupControllerProvider.notifier).createGroup(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הקבוצה נוצרה בהצלחה!'), backgroundColor: Colors.green),
      );
      // רענון פיד "הקבוצות שלי" כדי שהקבוצה החדשה תופיע שם מיד
      ref.read(myGroupsFeedProvider.notifier).refresh();
      context.pop(); // סגירת מסך היצירה וחזרה לפיד
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      groupControllerProvider,
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

    final groupState = ref.watch(groupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('יצירת קבוצה חדשה')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'שם הקבוצה (עד 30 תווים)')),
            const SizedBox(height: 16),
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'תיאור קצר (רשות)')),
            const SizedBox(height: 24),
            
            const Text('בחר תחומי עניין (1 עד 5):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: groupState.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: groupState.isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('צור קבוצה', style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}