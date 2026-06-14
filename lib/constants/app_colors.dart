import 'dart:ui';

/// Colour palette from the planning document.
///
/// Every hex value comes from Section 4.1. No invented colours.
///
/// Reference: Section 4.1 -- Colour Palette.
class AppColors {
  AppColors._();

  /// Full game canvas background. Off Black.
  static const Color kBackground = Color(0xFF111111);

  /// HUD bar, card panels, overlays. Dark Grey.
  static const Color kSurface = Color(0xFF1E1E1E);

  /// Scores, labels, shape fills. Off White.
  static const Color kPrimaryText = Color(0xFFF2F2F2);

  /// Sub-labels, captions. Mid Grey.
  static const Color kSecondaryText = Color(0xFF8A8A8A);

  /// Forbidden border, combo badge, buttons. Clean Blue.
  static const Color kAccent = Color(0xFF3B82F6);

  /// Score-pop, ring. Functional only. Green.
  static const Color kCorrect = Color(0xFF22C55E);

  /// Screen flash, lost-life icon. Functional only. Red.
  static const Color kWrong = Color(0xFFEF4444);

  /// Combo decay arc below 20% and forbidden change warning only --
  /// not for general use. Amber.
  static const Color kDecayWarning = Color(0xFFF59E0B);
}
