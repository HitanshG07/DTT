import 'dart:ui';

import 'base_shape.dart';

/// Plus-sign (cross) shape painter.
///
/// Symmetric, hardest to track at Level 5. Smallest visual size.
/// Reference: Section 4.2 -- S7 Cross.
class CrossShape extends BaseShape {
  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    final armWidth = size.width / 3;
    final armHeight = size.height / 3;
    final path = Path()
      // Top of vertical bar
      ..moveTo(armWidth, 0)
      ..lineTo(armWidth * 2, 0)
      // Right turn to horizontal bar
      ..lineTo(armWidth * 2, armHeight)
      ..lineTo(size.width, armHeight)
      // Down to bottom of right arm
      ..lineTo(size.width, armHeight * 2)
      // Left turn back to vertical bar
      ..lineTo(armWidth * 2, armHeight * 2)
      ..lineTo(armWidth * 2, size.height)
      // Bottom of vertical bar
      ..lineTo(armWidth, size.height)
      // Left turn to left arm
      ..lineTo(armWidth, armHeight * 2)
      ..lineTo(0, armHeight * 2)
      // Up to top of left arm
      ..lineTo(0, armHeight)
      // Right turn back to start
      ..lineTo(armWidth, armHeight)
      ..close();
    canvas.drawPath(path, paint);
  }
}
