import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/create_thread_provider.dart';
import '../../../group/providers/my_groups_list_provider.dart'; // הייבוא החדש
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_error_snackbar.dart';
import '../../providers/discovery_feed_provider.dart';

class CreateThreadScreen extends ConsumerStatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  ConsumerState<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends ConsumerState<CreateThreadScreen> {
  final _contentController = TextEditingController();
  
  String _bgType = 'color';
  String _bgValue = '#6200EE';
  Color _currentColor = AppColors.primary;
  File? _selectedImage;
  
  // המשתנה שישמור את ה-ID של הקבוצה שנבחרה
  String? _selectedGroupId;

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
        _bgValue = 'local_file';
      });
    }
  }

  void _setColor(Color color) {
    setState(() {
      _bgType = 'color';
      _currentColor = color;
      _selectedImage = null;
      _bgValue = '#${color.value.toRadixString(16).substring(2)}'; 
    });
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      CustomErrorSnackbar.show(context, 'פוסט לא יכול להיות ריק');
      return;
    }

    // קביעת הקבוצה שאליה מפרסמים
    String? finalGroupId = _selectedGroupId;
    
    // אם המשתמש לא נגע ב-Dropdown, ניקח את הקבוצה הראשונה ברשימה כברירת מחדל
    if (finalGroupId == null) {
      final groupsList = ref.read(myGroupsListProvider).value;
      if (groupsList != null && groupsList.isNotEmpty) {
        finalGroupId = groupsList.first.id;
      } else {
        CustomErrorSnackbar.show(context, 'עליך להיות חבר בקבוצה כדי לפרסם פוסט');
        return;
      }
    }

    // הקריאה האמיתית לשרת עם ה-ID של הקבוצה!
    final success = await ref.read(createThreadProvider.notifier).createThread(
      groupId: finalGroupId,
      content: content,
      bgType: _bgType,
      bgValue: _bgValue,
      imageFile: _selectedImage,
    );

    if (success && mounted) {
      CustomErrorSnackbar.showSuccess(context, 'הפוסט עלה לאוויר!');
      ref.invalidate(discoveryFeedProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final createThreadState = ref.watch(createThreadProvider);
    final isLoading = createThreadState.isLoading;
    
    // מאזין לרשימת הקבוצות של המשתמש
    final myGroupsAsync = ref.watch(myGroupsListProvider);

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
          // רקע הפוסט
          Positioned.fill(
            child: _bgType == 'image' && _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : Container(color: _currentColor),
          ),
          
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: AppColors.bottomScrim)),
          ),

          // תוכן המסך מעל הרקע
          SafeArea(
            child: Column(
              children: [
                // === ה-Dropdown לבחירת קבוצה ===
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: myGroupsAsync.when(
                    data: (groups) {
                      if (groups.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: const Text('אין קבוצות מחוברות', style: TextStyle(color: Colors.white)),
                        );
                      }
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black45, // שקוף למחצה כדי להשתלב עם הרקע
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            // אם לא נבחרה קבוצה, נציג את הראשונה
                            value: _selectedGroupId ?? groups.first.id,
                            dropdownColor: Colors.grey[900],
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            items: groups.map((group) {
                              return DropdownMenuItem(
                                value: group.id,
                                child: Text(group.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedGroupId = val);
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 40, width: 40, 
                      child: CircularProgressIndicator(color: Colors.white)
                    ),
                    error: (err, _) => Text('שגיאה בטעינת קבוצות: ${err.toString()}', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                
                // === אזור הזנת הטקסט ===
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
              ],
            ),
          ),

          // סרגל בחירת רקע (נשאר בדיוק אותו דבר)
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