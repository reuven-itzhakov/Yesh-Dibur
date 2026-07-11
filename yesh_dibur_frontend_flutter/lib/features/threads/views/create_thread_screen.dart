import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../feed/providers/feed_provider.dart';
import '../models/create_thread_request.dart';
import '../providers/thread_controller.dart';

class CreateThreadScreen extends ConsumerStatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  ConsumerState<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends ConsumerState<CreateThreadScreen> {
  final _contentController = TextEditingController();
  String? _selectedGroupId;
  String _selectedBgColor = '#FF4A3F'; // ברירת מחדל: Electric Coral

  final List<String> _colorOptions = ['#FF4A3F', '#00D4FF', '#8A2BE2', '#2A2A35'];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('חובה לבחור קבוצה')));
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('התוכן לא יכול להיות ריק')));
      return;
    }

    final request = CreateThreadRequest(
      groupId: _selectedGroupId!,
      content: _contentController.text,
      bgType: 'color',
      bgValue: _selectedBgColor,
    );

    final success = await ref.read(threadControllerProvider.notifier).createThread(request);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הפוסט פורסם בהצלחה!'), backgroundColor: Colors.green),
      );
      
      // רענון פיד "הקבוצות שלי" כדי להציג את הפוסט החדש
      ref.read(myGroupsFeedProvider.notifier).refresh();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      threadControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stackTrace) {
            String message = error.toString();
            if (error is ServerException) message = error.message;
            if (error is ValidationException) message = 'שגיאת וולידציה:\n${error.errors}';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
          },
        );
      },
    );

    final threadState = ref.watch(threadControllerProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('פרסום פוסט חדש')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('שגיאה בטעינת הקבוצות: $err')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('עדיין לא הצטרפת או יצרת אף קבוצה.'));
          }

          // אתחול בטוח לערך הראשון ברשימה
          _selectedGroupId ??= groups.first.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('בחר קבוצה לפרסום:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(filled: true, fillColor: AppTheme.muted),
                  items: groups.map((g) {
                    return DropdownMenuItem(value: g.id, child: Text(g.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedGroupId = val),
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: _contentController,
                  maxLength: 500,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'מה יש לך להגיד?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                const Text('בחר צבע רקע:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _colorOptions.map((hexCode) {
                    final isSelected = _selectedBgColor == hexCode;
                    final color = Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBgColor = hexCode),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: threadState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: threadState.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('פרסם עכשיו', style: TextStyle(fontSize: 18)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}