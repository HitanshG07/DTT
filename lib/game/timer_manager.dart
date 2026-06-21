import 'game_state.dart';

/// Counts the Burst-mode round timer down and publishes it to [GameState].
///
/// Pure Dart -- no Flame, no Flutter (DTT_2.0_ROADMAP.md §1 guardrail, §7.2).
/// The game engine calls [tick] each frame (skipping frames it wants frozen,
/// e.g. during a forbidden-change warning or while paused) and reads
/// [isExpired] to decide when to end the round.
///
/// Seeds [GameState.timeRemaining] with [roundDuration] on construction so the
/// HUD shows the full bar immediately. Reference: §4 (Phase 1).
class TimerManager {
  /// Observable game state this manager writes [GameState.timeRemaining] to.
  final GameState state;

  /// Total round length in seconds.
  final double roundDuration;

  double _remaining;

  TimerManager({
    required this.state,
    required this.roundDuration,
  }) : _remaining = roundDuration {
    state.timeRemaining.value = _remaining;
  }

  /// Seconds left in the round (never negative).
  double get remaining => _remaining;

  /// Whether the round timer has run out.
  bool get isExpired => _remaining <= 0.0;

  /// Advances the countdown by [dt] seconds, clamping at 0, and writes the new
  /// value to [GameState.timeRemaining]. No-op once already expired.
  void tick(double dt) {
    if (_remaining <= 0.0) return;
    _remaining -= dt;
    if (_remaining < 0.0) _remaining = 0.0;
    state.timeRemaining.value = _remaining;
  }

  /// Adds [seconds] to the clock (e.g. Phase 3 checkpoint reward) and republishes.
  /// [seconds] may be negative to subtract (Phase 2 time penalties).
  void addTime(double seconds) {
    _remaining += seconds;
    if (_remaining < 0.0) _remaining = 0.0;
    state.timeRemaining.value = _remaining;
  }
}
