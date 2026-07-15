import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EE); // צבע ראשי (לדוגמה)
  static const Color secondary = Color(0xFF03DAC6); // צבע משני
  static const Color background = Color(0xFFF5F5F5); // צבע רקע כללי
  static const Color error = Color(0xFFB00020);
  
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color white = Colors.white;

  // הגרדיאנט הקריטי להגנה על טקסט שיושב על גבי תמונות בפלטפורמה (Overlay/Scrim)
  static const LinearGradient bottomScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Colors.black87,
      Colors.black54,
      Colors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );
}