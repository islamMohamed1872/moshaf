import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  // 🌑 Current base colors
  static const int scaffoldBg = 0xff151515;
  static const int containerDarkBorders = 0xff3E3E3E;
  static const int containerLightBorders = 0xffBFBFBF;
  static const int mainGreen = 0xff0F9D55;
  static const int lightBlack = 0xff2E2E2E;

  // 🟨 Gold theme support
  static bool isGoldMode = false;

  // 🟡 Gold palette
  static const int goldPrimary = 0xFFD4AF37; // Classic royal gold
  static const int goldAccent = 0xFFF5DEB3; // Light golden wheat
  static const int goldText = 0xFF5A4634;   // Elegant brown-gold text
  static const int goldBackground = 0xFFFAF3E0; // Soft creamy background
  static const int goldBorder = 0xFFE0C07D; // Gentle golden border

  // 🧠 Helper method (optional)
  static Color getPrimaryColor() {
    return isGoldMode
        ? const Color(goldPrimary)
        : const Color(mainGreen);
  }

  static Color getBorderColor({required bool isDark}) {
    if (isGoldMode) return const Color(goldBorder);
    return isDark
        ? const Color(containerDarkBorders)
        : const Color(containerLightBorders);
  }

  static Color getBackgroundColor({required bool isDark}) {
    if (isGoldMode) return const Color(goldBackground);
    return isDark
        ? const Color(scaffoldBg)
        : Colors.white;
  }

  static Color getTextColor({required bool isDark}) {
    if (isGoldMode) return const Color(goldText);
    return isDark ? Colors.white : Colors.black;
  }
}
