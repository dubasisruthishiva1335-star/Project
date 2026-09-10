import 'package:flutter/material.dart';

/// MyVault "White Shaded & Liquid Metal Black" UI Design System
class MyVaultColors {
  // Shaded White Backgrounds
  static const backgroundWhite = Color(0xFFF8FAFC);
  static const backgroundShaded = Color(0xFFF1F5F9);
  static const whiteCard = Color(0xFFFFFFFF);
  static const obsidian = Color(0xFF07080D); // Kept for backward compatibility

  // White Shading Gradients
  static const whiteShadingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
      Color(0xFFEEF2F6),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const ambientMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
    ],
  );

  // Metallic Black & Liquid Chrome Accents
  static const metalBlack = Color(0xFF14171A);
  static const metalDark = Color(0xFF0B0D0F);
  static const metalChrome = Color(0xFF2B3138);
  static const metalHighlight = Color(0xFF4A525D);

  static const metalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C323B),
      Color(0xFF14171A),
      Color(0xFF0B0D0F),
    ],
  );

  static const metalGlossGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF3B434C),
      Color(0xFF1E2328),
      Color(0xFF101316),
    ],
  );

  // Liquid Translucent Fills & Borders
  static const liquidTranslucentFill = Color(0x0C0F172A); // Soft liquid tint
  static const liquidTranslucentHover = Color(0x160F172A);
  static const liquidGlassBorder = Color(0x180F172A);
  static const liquidCardBorder = Color(0x10000000);
  static const glassFill = Color(0x08FFFFFF);
  static const glassBorder = Color(0x14FFFFFF);

  // Vibrant Brand Colors
  static const accentBlue = Color(0xFF2563EB);
  static const accentCyan = Color(0xFF0EA5E9);
  static const accentPurple = Color(0xFF7C3AED);
  static const accentEmerald = Color(0xFF059669);
  static const accentAmber = Color(0xFFD97706);
  static const accentRose = Color(0xFFE11D48);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  // Typography Colors for White Background
  static const textDark = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
  static const textLight = Color(0xFFCBD5E1);
}
