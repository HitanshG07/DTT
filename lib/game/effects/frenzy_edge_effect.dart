import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;

import '../../constants/app_fonts.dart';
import '../config/game_constants.dart';

/// FrenzyEdgeEffect — the "adrenaline contrast" cue for Frenzy Mode (Feature M).
///
/// Acing a memory checkpoint ignites a [GameConstants.kFrenzyDurationSeconds]
/// double-points sprint; this overlay makes that window unmistakable WITHOUT
/// obscuring the spawning shapes: gold bands hug only the four screen **edges**
/// (the centre play area stays clear), and a "×2 FRENZY" label sits up top.
///
/// Its lifetime equals the frenzy duration, so it auto-removes exactly when the
/// window ends; [DttGame] also removes it on round end so it can't bleed into
/// Game Over. Honours the **Reduce flashing** setting: when [reduced] is true the
/// bands hold a steady opacity (no pulse), matching the REVERSE-cue fallback.
class FrenzyEdgeEffect extends Component with HasGameReference {
  /// When true, hold a constant opacity instead of pulsing (accessibility).
  final bool reduced;

  /// Gold accent, matching the star gold used elsewhere in the UI.
  static const Color _gold = Color(0xFFF5B301);

  /// Thickness of the edge bands in logical pixels.
  static const double _band = 16.0;

  final double _duration = GameConstants.kFrenzyDurationSeconds;
  double _elapsed = 0.0;

  final Paint _paint = Paint()..style = PaintingStyle.fill;

  static final TextPaint _labelPaint = TextPaint(
    style: const TextStyle(
      fontFamily: AppFonts.kFontDisplay,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: _gold,
    ),
  );

  FrenzyEdgeEffect({required this.reduced});

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double w = game.size.x;
    final double h = game.size.y;

    // Steady when reduced; otherwise a 2.5 Hz sine pulse between 0.35 and 0.7.
    final double opacity = reduced
        ? 0.55
        : 0.35 + 0.35 * (0.5 + 0.5 * math.sin(_elapsed * math.pi * 2 * 2.5));

    // ignore: deprecated_member_use
    _paint.color = _gold.withOpacity(opacity);

    // Four edge bands — centre left clear so spawns stay readable.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, _band), _paint); // top
    canvas.drawRect(Rect.fromLTWH(0, h - _band, w, _band), _paint); // bottom
    canvas.drawRect(Rect.fromLTWH(0, 0, _band, h), _paint); // left
    canvas.drawRect(Rect.fromLTWH(w - _band, 0, _band, h), _paint); // right

    // "×2 FRENZY" banner just below the top band.
    _labelPaint.render(
      canvas,
      '×2 FRENZY',
      Vector2(w / 2, _band + 14.0),
      anchor: Anchor.center,
    );
  }
}
