import 'dart:async';

import 'config/game_constants.dart';
import 'config/shape_type.dart';
import 'game_controller.dart';
import 'game_state.dart';

/// Mock implementation of [GameController] for Stage 2 UI development.
///
/// Drives GameState notifiers with demo ticker behaviour:
///   - Score increments by 10 every 800 ms
///   - Multiplier cycles 1->2->3->4->5->1 every 3 s
///   - decayProgress drains from 1.0 to 0.0 over 4 s then resets
///   - One life drops every 10 s (starts at 3, floors at 0)
///   - forbiddenShape cycles through all 7 ShapeType values every 5 s
///
/// Uses dart:async Timer. Zero Flame imports.
///
/// Reference: Section 10.1, Section 10.3 -- Stage 1 MockGameController.
class MockGameController implements GameController {
  @override
  final GameState state = GameState();

  Timer? _scoreTimer;
  Timer? _multiplierTimer;
  Timer? _decayTimer;
  Timer? _lifeTimer;
  Timer? _forbiddenTimer;

  int _shapeIndex = 0;
  double _decayValue = 1.0;

  static const Duration _decayTickInterval = Duration(milliseconds: 50);
  static const double _decayDrainPerTick =
      1.0 / (GameConstants.kIdleDecaySeconds * 1000 / 50);

  @override
  void start() {
    _scoreTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) {
        state.score.value += GameConstants.kScorePerTap;
      },
    );

    _multiplierTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        final current = state.multiplier.value;
        state.multiplier.value =
            current >= GameConstants.kMaxCombo ? 1 : current + 1;
      },
    );

    _decayTimer = Timer.periodic(
      _decayTickInterval,
      (_) {
        _decayValue -= _decayDrainPerTick;
        if (_decayValue <= 0.0) {
          _decayValue = 1.0;
        }
        state.decayProgress.value = _decayValue;
      },
    );

    _lifeTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (state.lives.value > 0) {
          state.lives.value -= 1;
        }
      },
    );

    _forbiddenTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _shapeIndex = (_shapeIndex + 1) % ShapeType.values.length;
        state.forbiddenShape.value = ShapeType.values[_shapeIndex];
      },
    );

    state.forbiddenShape.value = ShapeType.values[0];
  }

  @override
  void pause() {
    _cancelTimers();
  }

  @override
  void resume() {
    start();
  }

  @override
  void quit() {
    _cancelTimers();
  }

  @override
  void dispose() {
    _cancelTimers();
    state.dispose();
  }

  void _cancelTimers() {
    _scoreTimer?.cancel();
    _scoreTimer = null;
    _multiplierTimer?.cancel();
    _multiplierTimer = null;
    _decayTimer?.cancel();
    _decayTimer = null;
    _lifeTimer?.cancel();
    _lifeTimer = null;
    _forbiddenTimer?.cancel();
    _forbiddenTimer = null;
  }
}
