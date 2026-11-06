import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for GlowAI.
/// Playfair Display: headings and branding only.
/// Inter: everything else (forms, buttons, descriptions).
///
/// Widgets should read these through `Theme.of(context).textTheme`
/// (see [textTheme]) instead of calling this class directly.
abstract final class AppTextStyles {
  static TextStyle get heading => GoogleFonts.playfairDisplay(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.3,
    color: AppColors.primary,
  );

  static TextStyle get brand => GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.primary,
  );

  static TextStyle get description => GoogleFonts.inter(
    fontSize: 16,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle get input =>
      GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary);

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static TextStyle get error => caption.copyWith(color: AppColors.error);

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textLabel,
  );

  static TextStyle get hint =>
      GoogleFonts.inter(fontSize: 16, color: AppColors.textHint);

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle get link =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700);

  /// Maps the styles above onto Material roles.
  static TextTheme get textTheme => TextTheme(
    headlineMedium: heading,
    titleLarge: brand,
    titleMedium: description,
    bodyLarge: input,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: label,
  );
}
