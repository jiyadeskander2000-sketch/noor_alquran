import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Emerald & Gold Palette
  static const Color goldLight = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFF3C64F);
  static const Color emeraldLight = Color(0xFF0F5132);
  static const Color emeraldDark = Color(0xFF10B981);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF9F7F2);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFEADBCE);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0A0F18);
  static const Color darkCard = Color(0xFF131D2D);
  static const Color darkCardBorder = Color(0xFF23354E);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: emeraldLight,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: emeraldLight,
        secondary: goldLight,
        surface: lightCard,
        onSurface: lightTextPrimary,
        onPrimary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: emeraldLight),
        titleTextStyle: GoogleFonts.cairo(
          color: emeraldLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightCardBorder, width: 0.8),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.cairo(color: lightTextPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.cairo(color: lightTextSecondary, fontSize: 14),
        titleLarge: GoogleFonts.cairo(color: emeraldLight, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: emeraldDark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: emeraldDark,
        secondary: goldDark,
        surface: darkCard,
        onSurface: darkTextPrimary,
        onPrimary: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: goldDark),
        titleTextStyle: GoogleFonts.cairo(
          color: goldDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkCardBorder, width: 0.8),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.cairo(color: darkTextPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.cairo(color: darkTextSecondary, fontSize: 14),
        titleLarge: GoogleFonts.cairo(color: goldDark, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
