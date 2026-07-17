import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/create_thread_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_error_snackbar.dart';
import '../../providers/discovery_feed_provider.dart'; // כדי לרענן את הפיד בסיום

class CreateThreadScreen extends ConsumerStatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  ConsumerState<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends ConsumerState<CreateThreadScreen> {
  final _contentController = TextEditingController();
  
  // הגדרות ברירת מחדל
  String _bgType = 'color';
  String _bgValue = '#6200EE'; // צבע ה-Primary שלנו (כמחרוזת)
  Color _currentColor = AppColors.primary;
  File? _selectedImage;

  // רשימת צבעים לבחירה מהירה
  final List<Color> _presetColors = [
    AppColors.primary,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.black87,
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _bgType = 'image';
        _bgValue = 'local_file'; // ציון זמני עד ההעלאה
      });
    }
  }

  void _setColor(Color color) {
    setState(() {
      _bgType = 'color';
      _currentColor = color;
      _selectedImage = null;
      // המרת צבע לפורמט Hex לטובת השרת
      _bgValue = '#${color.value.toRadixString(16).substring(2)}'; 
    });
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      CustomErrorSnackbar.show(context, 'פוסט לא יכול להיות ריק');
      return;
    }

    // TODO: בשלב זה אנחנו משתמשים ב-ID קשיח לצורך הבדיקה.
    // בהמשך, נוסיף כאן Dropdown שבו המשתמש בוחר לאיזו מקבוצותיו הוא מעלה את הפוסט.
    const dummyGroupId = 'group_12345'; 

    final success = await ref.read(createThreadProvider.notifier).createThread(
      groupId: dummyGroupId,
      content: content,
      bgType: _bgType,
      bgValue: _bgValue,
      imageFile: _selectedImage,
    );

    if (success && mounted) {
      CustomErrorSnackbar.showSuccess(context, 'הפוסט עלה לאוויר!');
      
      // רענון הפיד הראשי כדי שהפוסט יופיע מיד
      ref.invalidate(discoveryFeedProvider);
      
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final createThreadState = ref.watch(createThreadProvider);
    final isLoading = createThreadState.isLoading;

    ref.listen<AsyncValue<void>>(createThreadProvider, (_, state) {
      state.whenOrNull(error: (error, _) => CustomErrorSnackbar.show(context, error.toString()));
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('פרסם', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // רקע הפוסט (תמונה או צבע)
          Positioned.fill(
            child: _bgType == 'image' && _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : Container(color: _currentColor),
          ),
          
          // שכבת גרדיאנט שחורה להבטחת קריאות הטקסט (כמו בכרטיסיית הפוסט)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.bottomScrim,
              ),
            ),
          ),

          // אזור הטקסט
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Center(
                child: TextField(
                  controller: _contentController,
                  enabled: !isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.4),
                  textAlign: TextAlign.center,
                  maxLines: 8,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'מה תרצה לשתף?',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    counterStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // סרגל בחירת רקע (צבעים או תמונה) בתחתית
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // כפתור בחירת תמונה
                    GestureDetector(
                      onTap: isLoading ? null : _pickImage,
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(Icons.image, color: Colors.white),
                      ),
                    ),
                    
                    // רשימת צבעים
                    ..._presetColors.map((color) => GestureDetector(
                      onTap: isLoading ? null : () => _setColor(color),
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _bgType == 'color' && _currentColor == color ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}