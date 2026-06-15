import 'package:flame/components.dart';

/// ObjectPopIn — scale 0→1.0 over 80ms ease-out on every pool acquire (FR-02 enhancement)
class ObjectPopIn extends Component {
  final PositionComponent target;
  final double _duration = 0.08;
  double _elapsed = 0.0;

  ObjectPopIn({required this.target}) {
    target.scale = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= _duration) {
      target.scale = Vector2.all(1.0);
      removeFromParent();
      return;
    }

    final double t = _elapsed / _duration;
    // Quadratic ease-out curve: f(t) = t * (2 - t)
    final double scale = t * (2.0 - t);
    target.scale = Vector2.all(scale);
  }
}
