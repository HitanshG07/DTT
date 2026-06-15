import 'dart:ui';
import 'package:flame/components.dart';

/// ScreenFlash — full-screen rect at 15% opacity, colour parameter, fades in 0.15s (Section 6.4)
class ScreenFlash extends Component with HasGameReference {
  final Color color;
  final double _duration = 0.15;
  double _elapsed = 0.0;
  final Paint _paint = Paint();

  ScreenFlash({required this.color});

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double progress = (_elapsed / _duration).clamp(0.0, 1.0);
    // Start at 15% opacity and fade out to 0%
    final double opacity = 0.15 * (1.0 - progress);

    _paint
      ..style = PaintingStyle.fill
      // ignore: deprecated_member_use
      ..color = color.withOpacity(opacity);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      _paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }
}
