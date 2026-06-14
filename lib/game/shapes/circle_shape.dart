import 'dart:ui';

import 'base_shape.dart';

/// Filled ellipse shape painter.
///
/// Baseline reference shape. Easiest to identify.
/// Reference: Section 4.2 -- S1 Circle.
class CircleShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    canvas.drawOval(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }
}
