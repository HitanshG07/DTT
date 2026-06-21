import 'dart:ui';
import 'package:flame/components.dart';

/// Bomb-tap "white blast" feedback (2.0 Burst, DTT_2.0_ROADMAP.md §5).
///
/// A **single** ~150 ms pulse that fades out — never strobes, never repeats.
/// Opacity is **hard-capped at [kMaxOpacity] (0.75)** for seizure safety.
///
/// When [reduced] is true (the "Reduce flashing" accessibility setting), it
/// downgrades to a soft white **edge vignette** with no full-screen flash at
/// all — the seizure-safe alternative. The reduced path is capped even lower
/// ([kReducedMaxOpacity]). This effect and the toggle ship together (§5 / M2.4).
class WhiteBlastEffect extends Component with HasGameReference {
  /// Hard opacity ceiling for the full-screen pulse (seizure safety). Never
  /// exceeded; asserted by tests.
  static const double kMaxOpacity = 0.75;

  /// Opacity ceiling for the reduced-mode edge vignette.
  static const double kReducedMaxOpacity = 0.4;

  /// When true, render an edge vignette instead of a full-screen flash.
  final bool reduced;

  final double _duration = 0.15;
  double _elapsed = 0.0;
  final Paint _paint = Paint();

  WhiteBlastEffect({this.reduced = false});

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final double fade = 1.0 - progress; // single pulse: peak then fade, no loop
    final double w = game.size.x;
    final double h = game.size.y;

    if (reduced) {
      // Seizure-safe: soft white frame hugging the screen edges, no flash.
      final double opacity =
          (kReducedMaxOpacity * fade).clamp(0.0, kReducedMaxOpacity);
      final double band = (w < h ? w : h) * 0.12;
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = band
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, band * 0.5)
        // ignore: deprecated_member_use
        ..color = const Color(0xFFFFFFFF).withOpacity(opacity);
      canvas.drawRect(
        Rect.fromLTWH(band / 2, band / 2, w - band, h - band),
        _paint,
      );
    } else {
      final double opacity = (kMaxOpacity * fade).clamp(0.0, kMaxOpacity);
      _paint
        ..style = PaintingStyle.fill
        ..maskFilter = null
        // ignore: deprecated_member_use
        ..color = const Color(0xFFFFFFFF).withOpacity(opacity);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _paint);
    }
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
