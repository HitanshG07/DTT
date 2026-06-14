import 'dart:math' as math;
import 'dart:ui';

import 'base_shape.dart';

/// 5-sided regular polygon shape painter.
///
/// Visually similar to circle at small sizes -- intentional difficulty.
/// Reference: Section 4.2 -- S4 Pentagon.
class PentagonShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy);
    const sides = 5;
    const startAngle = -math.pi / 2;

    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = startAngle + (2 * math.pi * i / sides);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
