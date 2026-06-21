/// Per-level configuration for working-memory checkpoints (2.0 Phase 3, §6).
///
/// Pure Dart -- no Flame, no Flutter. A few targets per window are marked
/// "special" and carry a token; periodically a recall checkpoint pauses the
/// round timer and asks the player to recall the tokens they saw.
///
/// Disabled by default so 1.x configs and earlier levels are unaffected.
class CheckpointSpec {
  /// Whether this level has memory checkpoints at all.
  final bool enabled;

  /// Seconds between checkpoints (counted while the round is running).
  final double interval;

  /// How many special token-carrying targets to show per window.
  final int specialsPerWindow;

  /// How many tokens the player must recall (usually == specialsPerWindow).
  final int recallCount;

  /// When true the player must recall the tokens **in the order seen**
  /// (harder, higher levels); when false, set-recall (membership only).
  final bool orderMatters;

  /// How many extra (never-shown) tokens to offer as distractors in the modal.
  final int distractorCount;

  /// The token alphabet to draw from (e.g. letters; animals/emoji in polish).
  final List<String> tokens;

  /// Seconds added to the clock for a correct recall.
  final double rewardSeconds;

  /// Seconds removed from the clock for a wrong recall.
  final double penaltySeconds;

  const CheckpointSpec({
    this.enabled = false,
    this.interval = 20.0,
    this.specialsPerWindow = 3,
    this.recallCount = 3,
    this.orderMatters = false,
    this.distractorCount = 3,
    this.tokens = const ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'],
    this.rewardSeconds = 5.0,
    this.penaltySeconds = 3.0,
  });
}

/// A ready-to-present recall challenge built by [CheckpointManager].
///
/// [seen] are the tokens actually shown this window (the correct answer set,
/// in order). [options] is the shuffled set of choices shown in the modal
/// (the seen tokens plus distractors).
class CheckpointPrompt {
  final List<String> seen;
  final List<String> options;
  final bool orderMatters;
  final int recallCount;

  const CheckpointPrompt({
    required this.seen,
    required this.options,
    required this.orderMatters,
    required this.recallCount,
  });
}
