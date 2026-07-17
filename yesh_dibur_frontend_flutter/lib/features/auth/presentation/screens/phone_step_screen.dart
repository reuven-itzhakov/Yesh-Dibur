import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_error_snackbar.dart';

class PhoneStepScreen extends ConsumerStatefulWidget {
  const PhoneStepScreen({super.key});

  @override
  ConsumerState<PhoneStepScreen> createState() => _PhoneStepScreenState();
}

class _PhoneStepScreenState extends ConsumerState<PhoneStepScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // שלב א': בקשת קוד ב-SMS מ-Firebase
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // ניקוי המספר מרווחים ומקפים
    String rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-]'), '');
    String formattedPhone;

    // סידור הפורמט ל-E.164 תיקני עבור פיירבייס
    if (rawPhone.startsWith('+972')) {
      formattedPhone = rawPhone;
    } else if (rawPhone.startsWith('972')) {
      formattedPhone = '+$rawPhone';
    } else if (rawPhone.startsWith('0')) {
      formattedPhone = '+972${rawPhone.substring(1)}';
    } else {
      formattedPhone = '+972$rawPhone';
    }

    // עדכון ה-Provider עם המספר המסודר (לשמירה בשרת שלנו)
    ref.read(onboardingProvider.notifier).updatePhone(formattedPhone);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone, // כאן מעבירים את המספר המסודר
        verificationCompleted: (PhoneAuthCredential credential) async {
          // למקרים של אימות אוטומטי (לרוב באנדרואיד)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          CustomErrorSnackbar.show(context, e.message ?? 'שגיאה באימות המספר');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      CustomErrorSnackbar.show(context, 'אירעה שגיאה בשליחת הקוד');
    }
  }

  // שלב ב': אימות הקוד שהמשתמש הזין
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length < 6) {
      CustomErrorSnackbar.show(context, 'אנא הזן קוד חוקי בן 6 ספרות');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() => _isLoading = false);
      CustomErrorSnackbar.show(context, 'קוד שגוי, אנא נסה שוב');
    }
  }

  // התחברות ל-Firebase והמשך לשלב הבא באפליקציה
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      // כאן אנחנו מחברים את המשתמש ל-Firebase עם הטלפון
      // במידה ויהיה צורך, אפשר לקשר כאן גם את האימייל שהוזן קודם
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // אימות עבר בהצלחה! עוברים לשלב הבא של בניית הפרופיל
      context.push('/register/profile_setup');
    } catch (e) {
      setState(() => _isLoading = false);
      CustomErrorSnackbar.show(context, 'התחברות נכשלה');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('אימות מספר טלפון'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isOtpSent ? 'הזן את הקוד שקיבלת' : 'מה מספר הטלפון שלך?',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isOtpSent 
                    ? 'שלחנו קוד בן 6 ספרות למספר ${_phoneController.text}' 
                    : 'נישלח אליך קוד ב-SMS כדי לאמת את זהותך.',
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                
                if (!_isOtpSent)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'מספר טלפון',
                      hintText: '05X-XXXXXXX',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 9) {
                        return 'אנא הזן מספר טלפון תקין';
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'קוד אימות',
                      prefixIcon: const Icon(Icons.lock_clock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading 
                    ? null 
                    : (_isOtpSent ? _verifyOtp : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)
                      )
                    : Text(
                        _isOtpSent ? 'אמת והמשך' : 'שלח קוד', 
                        style: const TextStyle(color: AppColors.white, fontSize: 18)
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