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

  CheckpointManager({required this.spec, required this.random});

  /// Whether checkpoints are active for this level.
  bool get enabled => spec.enabled;

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

  /// Grades [selected] against the window's seen tokens and returns the time
  /// delta to apply (+reward on success, -penalty on failure). Resets the
  /// window afterwards so the next window starts clean.
  double resolve(List<String> selected) {
    final correct = _isCorrect(selected);
    reset();
    return correct ? spec.rewardSeconds : -spec.penaltySeconds;
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
