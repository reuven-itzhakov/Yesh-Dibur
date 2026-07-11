import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- צבעי הליבה (Dark First - Neon Tel Aviv) ---
  static const Color background = Color(0xFF13131A); // Deep Ink
  static const Color card = Color(0xFF1C1C26);
  static const Color primary = Color(0xFFFF4A3F); // Electric Coral
  static const Color secondary = Color(0xFF00D4FF); // Aqua Mint
  static const Color foreground = Color(0xFFF7F7FA);
  static const Color muted = Color(0xFF2A2A35);
  static const Color mutedForeground = Color(0xFFA0A0AB);
  static const Color destructive = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color border = Color(0x12FFFFFF); // 7% opacity white
  static const Color ring = Color(0xFFFF4A3F);

  // --- גרדיאנטים מרכזיים ---
  static const LinearGradient gradientA = LinearGradient(
    colors: [Color(0xFFFF4A3F), Color(0xFFFF8A00)], // Primary to Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientB = LinearGradient(
    colors: [Color(0xFF8A2BE2), Color(0xFF00D4FF)], // Purple to Aqua Mint
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientC = LinearGradient(
    colors: [Color(0xFFFF007F), Color(0xFF9400D3)], // Pink to Deep Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
        onPrimary: Colors.white,
        onSecondary: background,
        onSurface: foreground,
      ),
      // הגדרת פונטים - Rubik לכותרות, Assistant לגוף הטקסט
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rubik(color: foreground, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.rubik(color: foreground, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.rubik(color: foreground, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.assistant(color: foreground),
        bodyMedium: GoogleFonts.assistant(color: foreground),
        labelLarge: GoogleFonts.assistant(color: foreground, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), // radius-md
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), // radius-md
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ring),
        ),
      ),
    );
  }
}