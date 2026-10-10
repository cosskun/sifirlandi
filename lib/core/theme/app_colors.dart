import 'package:flutter/material.dart';

/// Centralized color palette and dynamic theme color helpers for Sıfırlandı!
class AppColors {
  // Brand Colors
  static const Color primaryBurgundy = Color(0xFF800020);
  static const Color accentNeonCrimson = Color(0xFFFF2D55);
  static const Color secondaryRose = Color(0xFFB57C8A);
  static const Color softRoseBorder = Color(0xFFE8D0D5);
  static const Color whatsappGreen = Color(0xFF25D366);

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF141416);
  static const Color darkSurface = Color(0xFF1E1E22);
  static const Color darkCard = Color(0xFF2C2C32);
  static const Color darkCardHighlight = Color(0xFF2C1E24);
  static const Color darkBorder = Color(0xFF383842);

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFFAF6F0);
  static const Color lightSurface = Color(0xFFF3E8EB);
  static const Color lightCard = Colors.white;
  static const Color lightCardHighlight = Color(0xFFFCEFF1);
  static const Color lightBorder = Color(0xFFE8D0D5);

  // Status & Gamification Colors
  static const Color gold = Color(0xFFFFCC00);
  static const Color amber = Color(0xFFFF9500);
  static const Color emeraldGreen = Color(0xFF34C759);
  static const Color cyanAccent = Color(0xFF00C7BE);
  static const Color purpleAccent = Color(0xFFAF52DE);

  // Dynamic Theme Helpers
  static Color primary(bool isDark) => isDark ? accentNeonCrimson : primaryBurgundy;
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color card(bool isDark) => isDark ? darkSurface : lightCard;
  static Color cardAlt(bool isDark) => isDark ? darkCard : lightCardHighlight;
  static Color textPrimary(bool isDark) => isDark ? Colors.white : const Color(0xFF2C2526);
  static Color textSecondary(bool isDark) => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder.withValues(alpha: 0.5);
  static Color shadow(bool isDark) => isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03);
}
