/// Compile-time developer toggles for local testing only.
///
/// **Ship safety:** every flag here MUST default to `false` for release. When a
/// flag is on, the affected screen shows a visible `[DEV UNLOCK]`-style badge so
/// a debug build can never be mistaken for production. These flags only widen
/// *access* (e.g. which levels are tappable) — they never alter scoring,
/// difficulty, or the cognitive-training data integrity guarantees.
class DebugFlags {
  DebugFlags._();

  /// When `true`, every level on the map is unlocked and playable regardless of
  /// star progress, so the whole 30-level campaign can be reached for testing.
  ///
  /// Star records (`getStars`) are untouched — this only short-circuits the
  /// unlock gate. Keep `false` for any build that leaves this machine.
  static const bool unlockAllLevels = false;
}
