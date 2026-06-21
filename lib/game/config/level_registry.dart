import 'level_config.dart';
import 'level_generator.dart';
import 'star_thresholds.dart';

/// Registry of all level configurations.
///
/// As of 2.0 Phase 4 the 30 levels are **generated** from [LevelGenerator]
/// (sawtooth curve + flavors + human-limit caps) rather than hand-typed. The
/// public API ([forLevel], [levels], [levelCount]) is unchanged so callers and
/// the engine are unaffected — difficulty still lives entirely in [LevelConfig].
///
/// `_starOverrides` is the mandatory hand-tuning hook (guardrail): any level
/// whose generated star thresholds play badly in playtest is overridden here,
/// without touching the curve. Values below are conservative placeholders for
/// the late "Gauntlet" levels and will be tuned on-device.
///
/// Reference: DTT_2.0_ROADMAP.md §7 (Phase 4A), Section 3.1, 3.3.
class LevelRegistry {
  LevelRegistry._();

  /// Total number of levels (6 worlds × 5).
  static const int levelCount = LevelGenerator.totalLevels; // 30

  /// Hand-tuned star-threshold overrides (playtest-driven). Keyed by 1-indexed
  /// level. Empty entries fall back to the generated baseline.
  static const Map<int, StarThresholds> _starOverrides = {
    // Late Gauntlet levels: realistic human scores fall below the formula's
    // baseline under full cognitive load, so ease the cutoffs. Tune on-device.
    29: StarThresholds(one: 900, two: 1500, three: 2200),
    30: StarThresholds(one: 1000, two: 1700, three: 2500),
  };

  static const LevelGenerator _generator =
      LevelGenerator(starOverrides: _starOverrides);

  /// Returns the [LevelConfig] for the given 1-indexed [level].
  ///
  /// Clamps to the valid range [1, levelCount]. Reference: Section 3.3.
  static LevelConfig forLevel(int level) => _generator.forLevel(level);

  /// All level configurations (1-indexed in order). Computed on demand.
  static List<LevelConfig> get levels =>
      [for (int n = 1; n <= levelCount; n++) _generator.forLevel(n)];
}
