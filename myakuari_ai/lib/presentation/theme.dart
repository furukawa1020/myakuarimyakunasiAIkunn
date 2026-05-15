import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── High-Tech Cyber Palette ──
  static const Color background = Color(0xFF01080E); // Deep Space Black
  static const Color systemGreen = Color(0xFF00FF41); // Matrix Green
  static const Color warningAmber = Color(0xFFFFB000); // Terminal Amber
  static const Color alertRed = Color(0xFFFF2E2E); // System Alert Red
  static const Color cyberCyan = Color(0xFF00E5FF); // Data Flow Cyan
  static const Color textMain = Color(0xFFE0E0E0);
  static const Color textDim = Color(0xFF666666);
  static const Color cardBg = Color(0xFF05121B); // Deep Blue-Black Card

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.shareTechMonoTextTheme(ThemeData.dark().textTheme);
    
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: systemGreen,
      fontFamily: GoogleFonts.shareTechMono().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: systemGreen,
        secondary: cyberCyan,
        error: alertRed,
        surface: cardBg,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textMain,
        displayColor: systemGreen,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF1A2F3F), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: systemGreen,
          side: const BorderSide(color: systemGreen, width: 1.5),
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.shareTechMono(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
