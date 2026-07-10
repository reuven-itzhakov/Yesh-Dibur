import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // המרת הצבעים מתוך styles.css
  static const Color background = Color(0xFF161122); // Deep Ink
  static const Color card = Color(0xFF1E182D);
  static const Color primary = Color(0xFFFF6B6B); // Electric Coral
  static const Color secondary = Color(0xFF4ECDC4); // Aqua Mint
  static const Color muted = Color(0xFF2A2438);
  static const Color textForeground = Color(0xFFF7F7F7);
  static const Color textMuted = Color(0xFF9E9AA7);
  static const Color destructive = Color(0xFFFF4C4C);

  // יצירת ה-Theme המרכזי של האפליקציה
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: card,
        error: destructive,
      ),
      // הגדרת הפונטים (דורש הוספת החבילה google_fonts ל-pubspec.yaml)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rubik(color: textForeground, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.rubik(color: textForeground, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.assistant(color: textForeground, fontSize: 16),
        bodyMedium: GoogleFonts.assistant(color: textMuted, fontSize: 14),
      ),
      // עיצוב כרטיסיות (Border Radius לפי המוגדר ב-CSS)
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // --radius-xl
        ),
        elevation: 8,
      ),
      // עיצוב התפריט התחתון
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}