import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/onboarding_provider.dart';
import '../../data/models/user_model.dart';
import '../widgets/location_picker_btn.dart';
import '../widgets/interests_selector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_error_snackbar.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _selectedDate;
  LocationModel? _selectedLocation;
  List<String> _selectedInterests = [];

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)), // גיל דיפולטיבי 16
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null) {
      CustomErrorSnackbar.show(context, 'אנא בחר תאריך לידה');
      return;
    }
    
    if (_selectedLocation == null) {
      CustomErrorSnackbar.show(context, 'אנא הוסף את המיקום שלך');
      return;
    }
    
    if (_selectedInterests.length != 5) {
      CustomErrorSnackbar.show(context, 'יש לבחור בדיוק 5 תחומי עניין');
      return;
    }

    ref.read(onboardingProvider.notifier).updateProfileData(
      username: _usernameController.text.trim(),
      birthDate: _selectedDate,
      location: _selectedLocation,
    );
    ref.read(onboardingProvider.notifier).updateInterests(_selectedInterests);

    final success = await ref.read(onboardingProvider.notifier).submitRegistration();
    
    if (success && mounted) {
      CustomErrorSnackbar.showSuccess(context, 'החשבון נוצר בהצלחה!');
      context.go('/'); 
    } else {
      final errorMsg = ref.read(onboardingProvider).errorMessage;
      if (errorMsg != null && mounted) {
        CustomErrorSnackbar.show(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('השלמת פרופיל'), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const Text('צעד אחרון!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // שם משתמש
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'שם משתמש',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 20),
              
              // תאריך לידה
              OutlinedButton.icon(
                onPressed: _pickBirthDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_selectedDate == null 
                  ? 'בחירת תאריך לידה' 
                  : 'תאריך לידה: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              
              // איתור מיקום
              LocationPickerBtn(
                onLocationSelected: (loc) => setState(() => _selectedLocation = loc),
              ),
              const SizedBox(height: 24),
              
              // תחומי עניין
              const Text('בחרו 5 תחומי עניין:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InterestsSelector(
                onInterestsChanged: (interests) => setState(() => _selectedInterests = interests),
              ),
              const SizedBox(height: 32),
              
              // כפתור סיום
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Text('סיום והתחברות', style: TextStyle(color: AppColors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}