import 'package:flame/components.dart';
import '../dtt_game.dart';

/// SlowMotionEffect — timeScale 1.0→0.4 (50ms), hold (250ms), →1.0 (50ms) on wrong tap (FR-09 enhancement)
class SlowMotionEffect extends Component with HasGameReference<DttGame> {
  static const double _rampDownDuration = 0.05;
  static const double _holdDuration = 0.25;
  static const double _rampUpDuration = 0.05;
  static const double _targetTimeScale = 0.4;

  double _elapsed = 0.0;

  @override
  void update(double dt) {
    // Note: dt is real-time delta. We use it to update the slow-motion timeline.
    super.update(dt);
    _elapsed += dt;

    if (_elapsed < _rampDownDuration) {
      // Ramp down 1.0 -> 0.4
      final double t = _elapsed / _rampDownDuration;
      game.timeScale = 1.0 - (1.0 - _targetTimeScale) * t;
    } else if (_elapsed < _rampDownDuration + _holdDuration) {
      // Hold at 0.4
      game.timeScale = _targetTimeScale;
    } else if (_elapsed < _rampDownDuration + _holdDuration + _rampUpDuration) {
      // Ramp up 0.4 -> 1.0
      final double t = (_elapsed - _rampDownDuration - _holdDuration) / _rampUpDuration;
      game.timeScale = _targetTimeScale + (1.0 - _targetTimeScale) * t;
    } else {
      // Done, reset to 1.0
      game.timeScale = 1.0;
      removeFromParent();
    }
  }
}
