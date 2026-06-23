/// Game-wide constants derived from the planning document.
///
/// Every value traces to a specific section. These are gameplay
/// parameters -- UI-specific sizes live in app_sizes.dart.
///
/// Reference: Sections 1, 2, 3, 4, 7.
class GameConstants {
  GameConstants._();

  /// Minimum tap hitbox size in logical pixels (NFR-07, Section 3.3).
  static const double kMinHitbox = 48.0;

  /// Distance in px for proximity warning flash (FR-15, Section 2.5).
  static const double kProximityRadius = 80.0;

  /// Minimum spawn separation in logical pixels (FR-20, Section 3.2).
  static const double kOverlapRadius = 60.0;

  /// Duration of warmup window in seconds (FR-18, Section 2.6).
  static const int kWarmupDuration = 12;

  /// Forbidden must appear at least once within this interval
  /// in seconds (FR-19, Section 2.5).
  static const int kForbiddenGuaranteeInterval = 8;

  /// Pre-created FallingObject instances in the pool (NFR-05, Section 0.5).
  static const int kMaxPoolSize = 20;

  /// Seconds of no tapping before combo drops 1 step (Section 2.3).
  static const double kIdleDecaySeconds = 4.0;

  /// Combo decay arc pulses amber below this threshold (FR-16, Section 4.4).
  static const double kComboDecayWarningPercent = 0.20;

  /// timeScale target during wrong-tap slow-motion (Section 4.5).
  static const double kSlowMotionScale = 0.4;

  /// Milliseconds to hold at slow-motion scale (Section 4.5).
  static const int kSlowMotionHoldMs = 50;

  /// Milliseconds to ramp in/out of slow-motion scale (Section 4.5).
  static const int kSlowMotionRampMs = 250;

  /// Object pop-in scale animation duration in ms (Section 4.5, 6.4).
  static const int kObjectPopInDurationMs = 80;

  /// Milestone overlay display duration in ms (FR-10, Section 2.3).
  static const int kMilestoneOverlayDurationMs = 1500;

  /// Forbidden intro display duration in seconds (Section 4.6).
  static const int kForbiddenIntroDurationS = 3;

  /// Mid-round forbidden change warning duration in seconds (Section 4.6).
  static const double kForbiddenChangeDurationS = 1.5;

  /// Base points per correct tap (Section 2.3).
  static const int kScorePerTap = 10;

  /// Maximum combo multiplier (Section 2.3).
  static const int kMaxCombo = 5;

  /// Starting lives per round (Section 2.4, FR-05).
  static const int kLives = 3;

  // --- 2.0 Spatial Burst (DTT_2.0_ROADMAP.md §4, Phase 1) ---

  /// Logical px reserved at the top of the burst play area so objects never
  /// spawn behind the HUD bar (72 px) + the countdown bar. The HUD is a Flutter
  /// overlay drawn over the full-screen GameWidget, so the engine must avoid it.
  static const double kBurstPlayAreaTopInset = 88.0;

  /// Logical px reserved at the bottom of the burst play area (clears the pause
  /// button and SafeArea inset).
  static const double kBurstPlayAreaBottomInset = 72.0;

  /// Seconds subtracted from the round clock when the forbidden shape is tapped
  /// (2.0 time economy, §5). Replaces the 1.x life loss in Burst mode.
  static const double kForbiddenTimePenalty = 2.0;

  /// Seconds subtracted from the round clock when a bomb is tapped (§5). Bombs
  /// cost more than the forbidden shape because they are always-salient.
  static const double kBombTimePenalty = 4.0;

  // --- Feature M: Frenzy Mode (memory-checkpoint reward) ---

  /// Length in seconds of the Frenzy window ignited by acing a memory
  /// checkpoint. During it, correct taps score [kFrenzyScoreMultiplier]× base.
  static const double kFrenzyDurationSeconds = 5.0;

  /// Per-tap score multiplier applied on top of the combo during Frenzy Mode.
  /// Points are still *earned* tap-by-tap, so this rewards the sprint without
  /// flat-score inflation. Bomb/forbidden penalties are unaffected (integrity).
  static const int kFrenzyScoreMultiplier = 2;
}
