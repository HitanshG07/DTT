import 'dart:ui';

import 'base_shape.dart';

/// Equilateral triangle shape painter, apex up.
///
/// Drawn with Path. Vertices: top-centre, bottom-left, bottom-right.
/// Reference: Section 4.2 -- S3 Triangle.
class TriangleShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
}
