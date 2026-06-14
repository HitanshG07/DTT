import 'dart:math' as math;
import 'dart:ui';

import 'base_shape.dart';

/// 5-point star shape painter.
///
/// Inner radius = 0.4 x outer radius.
/// Reference: Section 4.2 -- S5 Star.
class StarShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerRadius = math.min(cx, cy);
    final innerRadius = outerRadius * 0.4;
    const points = 5;
    const startAngle = -math.pi / 2;

    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = startAngle + (math.pi * i / points);
      final radius = i.isEven ? outerRadius : innerRadius;
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
