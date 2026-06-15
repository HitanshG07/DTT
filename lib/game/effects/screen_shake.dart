import 'dart:math';
import 'package:flame/components.dart';

/// ScreenShake — CameraComponent offset, oscillation ±6px, 0.2s (Section 6.4)
class ScreenShake extends Component with HasGameReference {
  final double _duration = 0.2;
  double _elapsed = 0.0;
  final Random _random = Random();
  late Vector2 _originalPosition;

  @override
  void onLoad() {
    super.onLoad();
    _originalPosition = game.camera.viewfinder.position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      game.camera.viewfinder.position.setFrom(_originalPosition);
      removeFromParent();
      return;
    }

    // Oscillate between -6px and +6px on both axes
    final double dx = (_random.nextDouble() * 2 - 1) * 6.0;
    final double dy = (_random.nextDouble() * 2 - 1) * 6.0;

    game.camera.viewfinder.position.setValues(
      _originalPosition.x + dx,
      _originalPosition.y + dy,
    );
  }
}
