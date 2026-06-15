import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import '../../constants/app_fonts.dart';

/// Floating "+10×N" rises and fades, y-axis tween, 0.3s (Section 6.4)
class ScorePop extends TextComponent {
  final double _duration = 0.3;
  double _elapsed = 0.0;
  final double _startY;
  final Color _color;

  ScorePop({
    required String text,
    required Vector2 position,
    required Color color,
  })  : _startY = position.y,
        _color = color,
        super(
          text: text,
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              fontFamily: AppFonts.kFontDisplay,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }

    final double progress = _elapsed / _duration;
    // Float up by 40 logical pixels over the duration
    position.y = _startY - (progress * 40.0);
    
    // Fade out by re-rendering text with faded color
    final double opacity = 1.0 - progress;
    textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: AppFonts.kFontDisplay,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _color.withValues(alpha: opacity),
      ),
    );
  }
}
