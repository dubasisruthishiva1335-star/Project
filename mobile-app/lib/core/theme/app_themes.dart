import 'package:flutter/material.dart';

class AppThemes {
  // Brand Accents
  static const Color brandCyan = Color(0xFF06B6D4);
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandPurple = Color(0xFF8B5CF6);
  static const Color brandEmerald = Color(0xFF10B981);
  static const Color brandGold = Color(0xFFF59E0B);

  // OLED Obsidian Dark Colors
  static const Color darkBackground = Color(0xFF07090E);
  static const Color darkSurface = Color(0xFF0F131C);
  static const Color darkCard = Color(0xFF161B26);
  static const Color darkBorder = Color(0xFF262D3D);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Metallic Gradients
  static const LinearGradient darkMetalGradient = LinearGradient(
    colors: [Color(0xFF1A1F2C), Color(0xFF0F131C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightMetalGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: lightTextPrimary,
    cardColor: lightCard,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0F172A),
      secondary: brandCyan,
      surface: lightSurface,
      error: Color(0xFFEF4444),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
    ),
    dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: brandCyan,
    cardColor: darkCard,
    colorScheme: const ColorScheme.dark(
      primary: brandCyan,
      secondary: brandBlue,
      surface: darkSurface,
      error: Color(0xFFF43F5E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
  );
}
