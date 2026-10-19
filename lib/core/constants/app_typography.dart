import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get brandTitle => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: AppColors.textPrimary,
  );

  static TextStyle get splashTitle => GoogleFonts.outfit(
    fontSize: 44,
    fontWeight: FontWeight.w900,
    letterSpacing: 4.0,
    color: AppColors.textPrimary,
  );

  static TextStyle get splashTagline => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  static TextStyle get screenTitle => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get storyCardTitle => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get storyCardDescription => GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get cinematicNarrative => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.6,
    letterSpacing: 0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get choiceKey => GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryYellow,
  );

  static TextStyle get choiceLabel => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get choiceHint => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static TextStyle get badgeText => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static TextStyle get buttonText => GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Colors.white,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get statNumber => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle get statLabel => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
