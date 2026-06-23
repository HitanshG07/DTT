import 'dart:math';

import 'config/checkpoint_spec.dart';

/// Drives working-memory checkpoints (2.0 Phase 3, §6). Pure Dart -- no Flame,
/// no Flutter (§7.2), so it is fully unit-testable.
///
/// Responsibilities:
///   * hand out tokens to "special" targets as they spawn ([assignToken]),
///     recording the per-window seen set;
///   * count down to the next checkpoint ([tick] / [isDue]);
///   * build the recall challenge ([buildPrompt]); and
///   * grade an answer and return the time delta ([resolve]).
///
/// The game engine owns the pause/modal lifecycle; this class owns the logic.
class CheckpointManager {
  final CheckpointSpec spec;
  final Random random;

  double _elapsed = 0.0;
  final List<String> _windowTokens = <String>[];

  /// Round-level tally for the Memory rating (Feature M). Counts every
  /// checkpoint resolved this round and how many were aced (fully correct).
  /// These persist across the per-window [reset]; the manager is recreated per
  /// round, so they start at 0 each round.
  int _shown = 0;
  int _perfect = 0;

  CheckpointManager({required this.spec, required this.random});

  /// Whether checkpoints are active for this level.
  bool get enabled => spec.enabled;

  /// Checkpoints resolved this round (the denominator of the Memory rating).
  int get checkpointsShown => _shown;

  /// Checkpoints aced (fully correct) this round (the numerator).
  int get checkpointsPerfect => _perfect;

  /// Memory star rating (0–3) for a round, from the fraction of checkpoints
  /// aced: all → 3★, ≥ 2⁄3 → 2★, ≥ 1⁄3 → 1★, else 0. Returns 0 when none were
  /// shown (levels without checkpoints earn no Memory rating). Pure + static so
  /// it is trivially unit-testable and the only source of the thresholds.
  static int memoryStarsFor(int shown, int perfect) {
    if (shown <= 0) return 0;
    final double ratio = perfect / shown;
    if (ratio >= 1.0) return 3;
    if (ratio >= 2 / 3) return 2;
    if (ratio >= 1 / 3) return 1;
    return 0;
  }

  /// Tokens shown this window, in the order seen (the correct answer set).
  List<String> get windowTokens => List<String>.unmodifiable(_windowTokens);

  /// Assigns the next token to a spawning special target, or returns null if no
  /// special is needed right now (disabled, window already full, or alphabet
  /// exhausted). Records the token as "seen" this window.
  String? assignToken() {
    if (!spec.enabled) return null;
    if (_windowTokens.length >= spec.specialsPerWindow) return null;
    final available =
        spec.tokens.where((t) => !_windowTokens.contains(t)).toList();
    if (available.isEmpty) return null;
    final token = available[random.nextInt(available.length)];
    _windowTokens.add(token);
    return token;
  }

  /// Advances the checkpoint clock while the round is running.
  void tick(double dt) {
    if (spec.enabled) _elapsed += dt;
  }

  /// Whether a checkpoint should open now: enabled, the interval has elapsed,
  /// and at least one special was actually shown this window (nothing to recall
  /// otherwise).
  bool get isDue =>
      spec.enabled && _elapsed >= spec.interval && _windowTokens.isNotEmpty;

  /// Builds the recall challenge from the current window's seen tokens plus up
  /// to [CheckpointSpec.distractorCount] never-shown distractors, shuffled.
  CheckpointPrompt buildPrompt() {
    final seen = List<String>.from(_windowTokens);
    final distractors = spec.tokens.where((t) => !seen.contains(t)).toList()
      ..shuffle(random);
    final options = <String>[
      ...seen,
      ...distractors.take(spec.distractorCount),
    ]..shuffle(random);
    return CheckpointPrompt(
      seen: seen,
      options: options,
      orderMatters: spec.orderMatters,
      recallCount: spec.recallCount,
    );
  }

  /// Grades [selected] against the window's seen tokens and returns the
  /// [CheckpointOutcome] (the time delta to apply + whether it was aced). Updates
  /// the round tally and resets the window so the next one starts clean.
  ///
  /// Time stays all-or-nothing (+reward on a perfect recall, -penalty otherwise),
  /// as before; a perfect recall additionally ignites Frenzy Mode in the engine
  /// (Feature M) — that reward is handled by the caller via [CheckpointOutcome.perfect].
  CheckpointOutcome resolve(List<String> selected) {
    final correct = _isCorrect(selected);
    _shown++;
    if (correct) _perfect++;
    reset();
    return CheckpointOutcome(
      timeDelta: correct ? spec.rewardSeconds : -spec.penaltySeconds,
      perfect: correct,
    );
  }

  bool _isCorrect(List<String> selected) {
    if (spec.orderMatters) {
      if (selected.length != _windowTokens.length) return false;
      for (int i = 0; i < selected.length; i++) {
        if (selected[i] != _windowTokens[i]) return false;
      }
      return true;
    }
    // Set recall: same membership, same size, no extras.
    if (selected.length != _windowTokens.length) return false;
    return selected.toSet().containsAll(_windowTokens);
  }

  /// Clears the window (seen tokens + checkpoint clock). Called after [resolve]
  /// and available for round restarts.
  void reset() {
    _windowTokens.clear();
    _elapsed = 0.0;
  }
}

/// The graded result of a memory checkpoint (Feature M).
///
/// [timeDelta] is applied to the round clock (+reward / -penalty, all-or-nothing
/// as before). [perfect] is true iff the whole set was recalled correctly — the
/// engine uses it to ignite Frenzy Mode and to tally the Memory rating.
class CheckpointOutcome {
  final double timeDelta;
  final bool perfect;

  const CheckpointOutcome({required this.timeDelta, required this.perfect});
}
