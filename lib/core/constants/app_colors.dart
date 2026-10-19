import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds (Clean, Modern, Premium Dark)
  static const Color background = Color(0xFF0B0B0F);
  static const Color cardBackground = Color(0xFF15151B);
  static const Color surface = Color(0xFF15151B);
  static const Color surfaceLight = Color(0xFF1E1E26);
  static const Color surfaceElevated = Color(0xFF252530);
  static const Color cardDark = Color(0xFF15151B);
  static const Color cardBorder = Color(0xFF27272A);
  static const Color border = Color(0xFF27272A);

  // Brand Colors (Yellow is Main TWIST Brand Color)
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color secondaryYellow = Color(0xFFF4C400);
  static const Color primary = Color(0xFFFFD600);
  static const Color primaryPurple = Color(0xFF8B5CF6); // Kept for legacy compatibility
  static const Color accentPink = Color(0xFFEC4899);    // Kept for legacy compatibility
  static const Color primaryPink = Color(0xFFFFD600);   // Aliased to Primary Yellow for theme consistency
  static const Color primaryBlue = Color(0xFF3B82F6);   // Info blue

  // Functional Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Accents for tags & status
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGold = Color(0xFFFFD600);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentRed = Color(0xFFEF4444);

  // Text Colors (High Contrast)
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFA1A1AA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textPlaceholder = Color(0xFF52525B);

  // Subtle Overlays (No Heavy Blur)
  static const Color overlayDark = Color(0xCC0B0B0F);
  static const Color overlayLight = Color(0x0FFFFFFF);
  static const Color glassWhite = Color(0x08FFFFFF);
  static const Color glassBorder = Color(0xFF27272A);

  // Clean Yellow TWIST gradients
  static const LinearGradient twistBrandGradient = LinearGradient(
    colors: [primaryYellow, secondaryYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowGradient = LinearGradient(
    colors: [primaryYellow, secondaryYellow],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    colors: [primaryYellow, secondaryYellow],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [secondaryYellow, primaryYellow],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient bluePurpleGradient = LinearGradient(
    colors: [info, primaryYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secretEndingGradient = LinearGradient(
    colors: [Color(0xFFFFD600), Color(0xFFF4C400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyCardBackdropGradient = LinearGradient(
    colors: [Colors.transparent, Color(0x800B0B0F), Color(0xF50B0B0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.3, 0.7, 1.0],
  );

  static const LinearGradient choiceCardGradient = LinearGradient(
    colors: [Color(0xFF15151B), Color(0xFF15151B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeChoiceGradient = LinearGradient(
    colors: [primaryYellow, secondaryYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
