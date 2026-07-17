import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/create_group_provider.dart';
import '../../../auth/presentation/widgets/interests_selector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_error_snackbar.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  File? _selectedImage;
  List<String> _selectedInterests = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedInterests.isEmpty) {
      CustomErrorSnackbar.show(context, 'אנא בחר לפחות תחום עניין אחד');
      return;
    }

    // הקריאה ל-Provider
    final success = await ref.read(createGroupProvider.notifier).createGroup(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      interests: _selectedInterests,
      coverImage: _selectedImage,
    );

    if (success && mounted) {
      CustomErrorSnackbar.showSuccess(context, 'הקבוצה נוצרה בהצלחה!');
      context.pop(); // חזרה למסך הקודם
      
      // כאן מומלץ בהמשך לרענן את הפיד של "הקבוצות שלי" 
      // ref.invalidate(myGroupsFeedProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // האזנה למצב הטעינה כדי להציג חיווי ויזואלי ולתפוס שגיאות
    final createGroupState = ref.watch(createGroupProvider);
    
    // מאזין לשגיאות שיקפצו אוטומטית כסנאקבר
    ref.listen<AsyncValue<void>>(createGroupProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) => CustomErrorSnackbar.show(context, error.toString()),
      );
    });

    final isLoading = createGroupState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('יצירת קבוצה חדשה'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // אזור בחירת התמונה
              GestureDetector(
                onTap: isLoading ? null : _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate, size: 48, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('הוסף תמונת נושא (אופציונלי)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Container(
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // שם הקבוצה
              TextFormField(
                controller: _nameController,
                enabled: !isLoading,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: 'שם הקבוצה',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'חובה להזין שם לקבוצה' : null,
              ),
              const SizedBox(height: 16),
              
              // תיאור
              TextFormField(
                controller: _descController,
                enabled: !isLoading,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'על מה מדברים כאן?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'חובה להזין תיאור' : null,
              ),
              const SizedBox(height: 24),
              
              // תחומי עניין (מיחזור רכיב ה-InterestsSelector)
              const Text('בחרו תחומי עניין (עד 5):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InterestsSelector(
                onInterestsChanged: (interests) => setState(() => _selectedInterests = interests),
              ),
              const SizedBox(height: 32),
              
              // כפתור אישור
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Text('צור קבוצה', style: TextStyle(color: AppColors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}