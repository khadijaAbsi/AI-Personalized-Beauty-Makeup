import 'package:flutter/material.dart';

/// Centralized color palette for GlowAI.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color accentDark = Color(0xFF87515F);
  static const Color blush = Color(0xFFF3DDE2);
  // Surfaces
  static const Color background = Color(0xFFFFF9F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8D5DA);

  // Text
  static const Color textPrimary = Color(0xFF30272B);
  static const Color textLabel = Color(0xFF5E4352);
  static const Color textSecondary = Color(0xFF6F6469);
  static const Color textHint = Color(0xFF8C8186);

  // Feedback
  static const Color error = Color(0xFFB54752);

  // Disabled states
  static const Color disabledBackground = Color(0xFFE6D9DE);
  static const Color disabledForeground = Color(0xFF9A8E94);

  // Pressed overlay
  static const Color pressedOverlay = Color(0x1FFFFFFF);

  static const Color deepMauve = accentDark;
  static const Color blushPink = blush;
  static const Color warmIvory = background;
  static const Color white = surface;
  static const Color primaryText = textPrimary;
  static const Color labelText = textLabel;
  static const Color secondaryText = textSecondary;
  static const Color hintText = textHint;
}