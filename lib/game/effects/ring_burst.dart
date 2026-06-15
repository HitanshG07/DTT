import 'dart:ui';
import 'package:flame/components.dart';

/// RingBurst — expanding white circle, strokeWidth tapers to 0, 0.3s (Section 6.4)
class RingBurst extends PositionComponent {
  final double _duration = 0.3;
  double _elapsed = 0.0;
  final double _targetRadius;
  final Paint _paint = Paint();

  RingBurst({
    required Vector2 position,
    required double size,
  })  : _targetRadius = size * 1.25,
        super(
          position: position,
          size: Vector2.all(size),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final double currentRadius = progress * _targetRadius;
    
    // Stroke width tapers from 3.0 to 0.0
    final double strokeWidth = (1.0 - progress) * 3.0;

    if (strokeWidth > 0.0) {
      _paint
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(
        Offset(size.x / 2.0, size.y / 2.0),
        currentRadius,
        _paint,
      );
    }
  }
}
