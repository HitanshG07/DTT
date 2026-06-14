import 'dart:ui';

import 'base_shape.dart';

/// Diamond shape painter -- square rotated 45 degrees.
///
/// Confused with square under pressure -- deliberate difficulty.
/// Reference: Section 4.2 -- S6 Diamond.
class DiamondShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path()
      ..moveTo(cx, 0)
      ..lineTo(size.width, cy)
      ..lineTo(cx, size.height)
      ..lineTo(0, cy)
      ..close();
    canvas.drawPath(path, paint);
  }
}
