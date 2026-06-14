import 'dart:ui';

import 'base_shape.dart';

/// Rounded-rectangle shape painter.
///
/// Corner radius 6 distinguishes it from circle at small sizes.
/// Reference: Section 4.2 -- S2 Square.
class SquareShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      paint,
    );
  }
}
