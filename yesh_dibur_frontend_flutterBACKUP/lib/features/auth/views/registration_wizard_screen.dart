import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/registration_wizard_controller.dart';

class RegistrationWizardScreen extends ConsumerStatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  ConsumerState<RegistrationWizardScreen> createState() => _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState extends ConsumerState<RegistrationWizardScreen> {
  final PageController _pageController = PageController();
  
  // Controllers לשדות הטקסט השונים
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();

  final List<String> _availableInterests = [
    'פיתוח תוכנה', 'מציאות מדומה', 'טכנולוגיה', 'גיימינג', 'האקתונים בעפולה', 'ספורט', 'מוזיקה', 'טיולים'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _syncPageWithState(int step) {
    if (_pageController.hasClients && _pageController.page?.round() != step) {
      _pageController.animateToPage(step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationWizardControllerProvider);
    final regNotifier = ref.read(registrationWizardControllerProvider.notifier);

    // מסנכרן את האנימציה של העמוד ברגע שהסטייט מתעדכן
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPageWithState(regState.currentStep);
    });

    return Scaffold(
      appBar: AppBar(
        leading: regState.currentStep > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: regNotifier.previousStep)
            : IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/login')),
        title: Text('שלב ${regState.currentStep + 1} מתוך 9'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (regState.currentStep + 1) / 9,
            backgroundColor: AppTheme.muted,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (regState.errorMessage != null)
              Container(
                width: double.infinity,
                color: Colors.redAccent,
                padding: const EdgeInsets.all(8.0),
                child: Text(regState.errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // חסימת החלקה ידנית
                children: [
                  _buildStepContainer(
                    title: 'מה האימייל שלך?',
                    child: TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'אימייל')),
                    onNext: () => regNotifier.validateEmailAndProceed(_emailController.text),
                    isLoading: regState.isLoading,
                  ),
                  _buildStepContainer(
                    title: 'בחר סיסמה מאובטחת',
                    child: TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'סיסמה (לפחות 6 תווים)')),
                    onNext: () {
                      regNotifier.updateData(regState.copyWith(password: _passwordController.text));
                      regNotifier.nextStep();
                    },
                  ),
                  _buildStepContainer(
                    title: 'מה מספר הטלפון שלך?',
                    child: TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'מספר טלפון (מתחיל ב-05)')),
                    onNext: () => regNotifier.sendOtpAndProceed(_phoneController.text),
                    isLoading: regState.isLoading,
                  ),
                  _buildStepContainer(
                    title: 'הזן את קוד האימות (6 ספרות)',
                    child: TextField(controller: _otpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'קוד אימות')),
                    onNext: () => regNotifier.verifyOtpAndProceed(_otpController.text),
                    isLoading: regState.isLoading,
                  ),
                  _buildStepContainer(
                    title: 'בחר שם משתמש',
                    child: TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'שם משתמש (ייחודי)')),
                    onNext: () => regNotifier.validateUsernameAndProceed(_usernameController.text),
                    isLoading: regState.isLoading,
                  ),
                  _buildStepContainer(
                    title: 'מתי נולדת?',
                    child: ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
                        if (date != null) {
                          regNotifier.updateData(regState.copyWith(birthDate: date));
                        }
                      },
                      child: Text(regState.birthDate == null ? 'בחר תאריך' : '${regState.birthDate!.day}/${regState.birthDate!.month}/${regState.birthDate!.year}'),
                    ),
                    onNext: () => regState.birthDate != null ? regNotifier.nextStep() : regNotifier.setError('יש לבחור תאריך לידה'),
                  ),
                  _buildStepContainer(
                    title: 'מאיפה אתה?',
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.my_location), label: const Text('אתר מיקום אוטומטית'),
                          onPressed: regNotifier.detectLocationAndProceed,
                        ),
                        const SizedBox(height: 16),
                        const Text('או הזן ידנית:'),
                        TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'שם עיר')),
                      ],
                    ),
                    onNext: () {
                      if (_cityController.text.isNotEmpty) {
                        regNotifier.updateData(regState.copyWith(cityName: _cityController.text));
                        regNotifier.nextStep();
                      }
                    },
                    isLoading: regState.isLoading,
                  ),
                  _buildStepContainer(
                    title: 'בחר 5 תחומי עניין',
                    child: Wrap(
                      spacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = regState.interests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (_) {
                            final newList = List<String>.from(regState.interests);
                            isSelected ? newList.remove(interest) : (newList.length < 5 ? newList.add(interest) : null);
                            regNotifier.updateData(regState.copyWith(interests: newList));
                          },
                        );
                      }).toList(),
                    ),
                    onNext: () => regState.interests.length == 5 ? regNotifier.nextStep() : regNotifier.setError('חובה לבחור בדיוק 5 תחומי עניין'),
                  ),
                  _buildStepContainer(
                    title: 'תמונת פרופיל (אופציונלי)',
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50, 
                          backgroundImage: regState.profileImage != null ? FileImage(regState.profileImage!) : null,
                          child: regState.profileImage == null ? const Icon(Icons.person, size: 50) : null,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.image), label: const Text('בחר מהגלריה'),
                          onPressed: () async {
                            final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              regNotifier.updateData(regState.copyWith(profileImage: File(pickedFile.path)));
                            }
                          },
                        )
                      ],
                    ),
                    onNext: () async {
                      final success = await regNotifier.finishRegistration();
                      if (success && mounted) context.go('/home');
                    },
                    isLoading: regState.isLoading,
                    nextButtonText: 'סיום והרשמה',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // פונקציית עזר לבניית העיצוב האחיד של כל שלב
  Widget _buildStepContainer({
    required String title,
    required Widget child,
    required VoidCallback onNext,
    bool isLoading = false,
    String nextButtonText = 'המשך',
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          child,
          const Spacer(),
          ElevatedButton(
            onPressed: isLoading ? null : onNext,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : Text(nextButtonText, style: const TextStyle(fontSize: 18)),
          )
        ],
      ),
    );
  }
}