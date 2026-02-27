import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color textMain = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color cardBg = Color(0xFF1E1E1E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonPink,
      colorScheme: const ColorScheme.dark(
        primary: neonPink,
        secondary: neonCyan,
        surface: cardBg,
      ),
      textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
