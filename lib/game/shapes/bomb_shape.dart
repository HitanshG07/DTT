import 'dart:ui';

import 'base_shape.dart';

/// Always-salient bomb hazard painter (2.0 Burst, DTT_2.0_ROADMAP.md §5).
///
/// Unlike the other shapes, the bomb **ignores the supplied [paint] colour** and
/// draws with its own fixed, high-contrast palette so it is unmistakable against
/// the off-black canvas and never blends in with the off-white targets — a bomb
/// must read as "always avoid" at a glance. A bright rim plus a red fuse-spark
/// carry the salience (a plain black sphere would vanish on the dark canvas).
class BombShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w * 0.5;
    final double cy = h * 0.58; // body sits low; fuse occupies the top.
    final double r = w * 0.34;

    // Body: dark sphere, lifted off the off-black background.
    final body = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2B2B2B);
    canvas.drawCircle(Offset(cx, cy), r, body);

    // Bright rim so the bomb reads on the dark canvas (primary salience cue).
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..color = const Color(0xFFF2F2F2);
    canvas.drawCircle(Offset(cx, cy), r, rim);

    // Glint highlight.
    final glint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x66FFFFFF);
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.35), r * 0.18, glint);

    // Fuse curving up from the top of the body.
    final fuse = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8A8A8A);
    final fusePath = Path()
      ..moveTo(cx + r * 0.3, cy - r * 0.85)
      ..quadraticBezierTo(
        cx + r * 0.95,
        cy - r * 1.2,
        cx + r * 0.7,
        cy - r * 1.5,
      );
    canvas.drawPath(fusePath, fuse);

    // Red spark at the fuse tip — the always-danger cue.
    final spark = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFEF4444);
    canvas.drawCircle(Offset(cx + r * 0.7, cy - r * 1.5), w * 0.08, spark);
  }
}
