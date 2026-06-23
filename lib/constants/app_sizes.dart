import '../game/config/game_constants.dart';

/// UI-specific sizing constants from the planning document.
///
/// Re-exports gameplay-relevant sizes from [GameConstants] and adds
/// HUD and overlay dimensions from Section 4.4 and Section 4.6.
///
/// Reference: Sections 4.4, 4.6.
class AppSizes {
  AppSizes._();

  // --- Re-exported from GameConstants (Section 3.3, FR-15, FR-20) ---

  /// Minimum tap hitbox in logical pixels.
  static const double kMinHitbox = GameConstants.kMinHitbox;

  /// Proximity warning radius in logical pixels.
  static const double kProximityRadius = GameConstants.kProximityRadius;

  /// Spawn overlap prevention radius in logical pixels.
  static const double kOverlapRadius = GameConstants.kOverlapRadius;

  // --- HUD layout (Section 4.4) ---

  /// HUD bar height in logical pixels.
  ///
  /// Raised from the Section 4.4 nominal 56 px to fit the centre column's
  /// 28 px score stacked over the 40 px combo-decay badge (kComboBadgeSize)
  /// plus the right column's 36 px thumbnail and AVOID label. At 56 px the
  /// content overflowed the bar by ~13 px ("BOTTOM OVERFLOWED").
  static const double kHudHeight = 72.0;

  /// Heart icon size in logical pixels (24x24).
  static const double kHeartIconSize = 24.0;

  /// Spacing between heart icons in logical pixels.
  static const double kHeartSpacing = 8.0;

  /// Forbidden shape thumbnail in HUD (36x36) with dashed blue border.
  static const double kForbiddenThumbnailSize = 36.0;

  /// Forbidden shape size during intro phase (100x100, centred).
  /// Reference: Section 4.6.
  static const double kForbiddenIntroSize = 100.0;

  /// Combo badge diameter in logical pixels.
  static const double kComboBadgeSize = 40.0;

  /// Score font size in HUD (Space Grotesk Bold 36pt — the score is the HUD hero).
  static const double kHudScoreFontSize = 36.0;

  /// Round-time countdown font size in HUD (Space Grotesk Bold 22pt). Burst
  /// mode replaced the lives/hearts readout with this numeric mm:ss timer.
  static const double kHudTimeFontSize = 22.0;

  /// 'Avoid' label font size below forbidden thumbnail (Inter 10pt).
  static const double kForbiddenLabelFontSize = 10.0;
}
