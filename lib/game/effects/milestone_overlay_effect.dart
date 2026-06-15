import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;
import '../../constants/app_colors.dart';
import '../../constants/app_fonts.dart';

/// MilestoneOverlay — text banner slides in from top, auto-dismisses after 1.5s, does NOT pause gameplay (FR-10, Section 6.4)
class MilestoneOverlayEffect extends PositionComponent with HasGameReference {
  final String message;
  final double _duration = 1.5;
  double _elapsed = 0.0;

  final Paint _bgPaint = Paint()..color = AppColors.kSurface;
  final Paint _borderPaint = Paint()
    ..color = AppColors.kAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  late final TextComponent _textComponent;

  MilestoneOverlayEffect({required this.message});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Scale banner relative to screen width
    size = Vector2(game.size.x * 0.8, 60.0);
    // Initial position starts offscreen above the top
    position = Vector2(game.size.x * 0.1, -100.0);

    _textComponent = TextComponent(
      text: message,
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: AppFonts.kFontDisplay,
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: AppColors.kPrimaryText,
        ),
      ),
    );
    add(_textComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }

    final double progress = _elapsed / _duration;
    double targetY;

    if (progress < 0.15) {
      // Smooth slide-in to y=80 (below the 56px HUD height)
      final double t = progress / 0.15;
      targetY = -100.0 + (80.0 - (-100.0)) * t;
    } else if (progress > 0.85) {
      // Smooth slide-out back to y=-100
      final double t = (progress - 0.85) / 0.15;
      targetY = 80.0 + (-100.0 - 80.0) * t;
    } else {
      // Hold position
      targetY = 80.0;
    }

    position.y = targetY;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8.0),
    );
    canvas.drawRRect(rect, _bgPaint);
    canvas.drawRRect(rect, _borderPaint);
  }
}
