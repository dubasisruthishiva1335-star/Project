import 'package:flutter/material.dart';

/// MyVault "Liquid Glass UI" palette.
class MyVaultColors {
  static const obsidian = Color(0xFF07080D);
  static const accentBlue = Color(0xFF3E7BFF);
  static const accentCyan = Color(0xFF00D9F5);
  static const glassFill = Color(0x08FFFFFF); // rgba(255,255,255,0.03)
  static const glassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, accentCyan],
  );
}
