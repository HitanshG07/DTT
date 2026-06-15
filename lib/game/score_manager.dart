import 'dart:math' as math;

import 'config/game_constants.dart';
import 'game_state.dart';

/// All scoring, combo, accuracy, and idle decay logic. Pure Dart.
///
/// Reads/writes [GameState] ValueNotifiers. The UI reacts to notifier
/// changes automatically -- this class never touches Flutter widgets.
///
/// Reference: Section 2.2, 2.3, 2.4.
class ScoreManager {
  /// The observable game state driven by this manager.
  final GameState _state;

  /// Current combo multiplier (1--kMaxCombo).
  int _multiplier = 1;

  /// Consecutive correct taps toward the next multiplier step.
  int _consecutive = 0;

  /// Total taps registered (both correct and wrong).
  int _totalTapped = 0;

  /// Correct taps only.
  int _correctTapped = 0;

  /// Current streak of consecutive correct taps (for longest streak).
  int _currentStreak = 0;

  /// Longest streak of consecutive correct taps seen this round.
  int _longestStreak = 0;

  /// Seconds elapsed since the last correct tap (for idle decay).
  double _idleDecayTimer = 0.0;

  /// Previous multiplier value, used to detect combo changes.
  int _previousMultiplier = 1;

  /// Combo threshold: consecutive correct taps needed to increase multiplier.
  /// Each correct tap increments; when it reaches this value the
  /// multiplier steps up and the counter resets.
  /// Reference: Section 2.3 -- 'Each consecutive correct tap adds 1'.
  static const int kComboThreshold = 1;

  ScoreManager(this._state);

  /// The longest streak of consecutive correct taps this round.
  int get longestStreak => _longestStreak;

  /// The previous multiplier value before the last change.
  /// Used by DttGame to detect combo up/down events for audio.
  int get previousMultiplier => _previousMultiplier;

  /// The current multiplier value.
  int get multiplier => _multiplier;

  /// Processes a correct (non-forbidden) tap.
  ///
  /// 1. Increments tap counters.
  /// 2. Resets idle decay timer.
  /// 3. Builds combo if below max.
  /// 4. Awards points: kBasePoints * multiplier.
  /// 5. Updates streak tracking.
  void onCorrectTap() {
    _totalTapped++;
    _correctTapped++;
    _idleDecayTimer = 0.0;

    _previousMultiplier = _multiplier;

    if (_multiplier < GameConstants.kMaxCombo) {
      _consecutive++;
      if (_consecutive >= kComboThreshold) {
        _multiplier++;
        _consecutive = 0;
        _state.multiplier.value = _multiplier;
      }
    }

    final int points = GameConstants.kScorePerTap * _multiplier;
    _state.score.value += points;

    // Streak tracking
    _currentStreak++;
    _longestStreak = math.max(_longestStreak, _currentStreak);

    // Reset decay progress on correct tap (FR-16).
    _state.decayProgress.value = 1.0;
  }

  /// Processes a wrong (forbidden) tap.
  ///
  /// 1. Increments total tap counter (wrong tap counts as a tap).
  /// 2. Resets idle decay timer.
  /// 3. Resets combo consecutive counter.
  /// 4. Decrements multiplier if above 1.
  /// 5. Deducts one life.
  /// 6. Resets current streak.
  void onWrongTap() {
    _totalTapped++;
    _idleDecayTimer = 0.0;

    _previousMultiplier = _multiplier;
    _consecutive = 0;

    if (_multiplier > 1) {
      _multiplier--;
      _state.multiplier.value = _multiplier;
    }

    _state.lives.value -= 1;

    // Streak resets on wrong tap.
    _currentStreak = 0;
  }

  /// Processes a missed object (fell off screen without being tapped).
  ///
  /// Does NOT decrement lives.
  /// Does NOT affect combo.
  /// Reference: Section 2.1 -- objects falling off screen do not cost
  /// a life. Only tapping the forbidden shape does.
  void onMissed() {
    // Intentionally empty per planning document.
    // Missed objects have no penalty in the current design.
  }

  /// Advances the idle decay timer by [dt] seconds.
  ///
  /// If the player has not tapped for [idleDecaySeconds], the combo
  /// multiplier drops by 1 step. Reference: Section 2.3.
  void tick(double dt) {
    _idleDecayTimer += dt;

    // Update decay progress for the UI arc (FR-16).
    final double progress =
        1.0 - (_idleDecayTimer / GameConstants.kIdleDecaySeconds);
    _state.decayProgress.value = progress.clamp(0.0, 1.0);

    if (_idleDecayTimer >= GameConstants.kIdleDecaySeconds &&
        _multiplier > 1) {
      _previousMultiplier = _multiplier;
      _multiplier--;
      _state.multiplier.value = _multiplier;
      _idleDecayTimer = 0.0;
      _state.decayProgress.value = 1.0;
    }
  }

  /// Returns the accuracy percentage, or null if no taps have been
  /// registered.
  ///
  /// CRITICAL: returns null, not 0, when totalTapped == 0.
  /// Reference: Section 2.8, accuracy null rule.
  double? getAccuracyPercent() {
    if (_totalTapped == 0) return null;
    return (_correctTapped / _totalTapped) * 100.0;
  }
}