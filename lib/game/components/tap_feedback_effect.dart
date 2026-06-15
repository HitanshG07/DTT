import 'dart:ui';

import 'package:flame/components.dart';

import '../config/game_constants.dart';

/// A short-lived visual burst at the tap position.
///
/// Expands from 0 to [_targetSize] * 1.5 over [_lifetime] while
/// fading opacity from 1.0 to 0.0. Renders a filled circle.
/// Removes itself from the parent when the animation completes.
///
/// No Flutter imports. Uses dart:ui Paint + Canvas only.
///
/// Reference: Section 4.3.
class TapFeedbackEffect extends PositionComponent {
  /// The colour of the feedback burst.
  final Color _color;

  /// The base size of the effect.
  final double _targetSize;

  /// Duration of the effect in seconds.
  final double _lifetime;

  /// Elapsed time since the effect started.
  double _elapsed = 0.0;

  /// Cached paint object to avoid allocations.
  final Paint _paint = Paint();

  /// Creates a tap feedback effect at [position] with the given
  /// [color] and [size].
  ///
  /// Lifetime is driven by [GameConstants.kObjectPopInDurationMs]
  /// converted to seconds. The effect is self-removing.
  TapFeedbackEffect({
    required Vector2 position,
    required Color color,
    required double size,
  })  : _color = color,
        _targetSize = size,
        _lifetime = 300.0 / 1000.0,
        super(
          position: position,
          size: Vector2.all(size),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double progress = (_elapsed / _lifetime).clamp(0.0, 1.0);

    // Scale from 0 to targetSize * 1.5 over lifetime.
    final double currentRadius = (_targetSize * 1.5 * progress) / 2.0;

    // Fade from 1.0 to 0.0 over lifetime.
    final double opacity = 1.0 - progress;

    _paint
      ..style = PaintingStyle.fill
      ..color = _color.withValues(alpha: opacity);

    canvas.drawCircle(
      Offset(size.x / 2.0, size.y / 2.0),
      currentRadius,
      _paint,
    );
  }
}