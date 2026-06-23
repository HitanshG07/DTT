import 'dart:ui';

import 'base_shape.dart';

/// Triangle shape painter, apex up — optically centred.
///
/// An apex-up triangle's centroid sits 1/3 of the way up from its base, so
/// filling the box edge-to-edge (apex at y=0, base at y=height) puts the
/// centroid at 2/3 height and makes the triangle read as bottom-heavy / shifted
/// down next to symmetric shapes (circle, square) — visible in the HUD "AVOID"
/// thumbnail and on triangle objects in play. Bringing the base up to 3/4 height
/// lands the centroid exactly at the box centre (`(0 + 0.75h + 0.75h)/3 = 0.5h`),
/// so it sits level with the other shapes. Width stays full.
///
/// Drawn with Path. Vertices: top-centre, then base-right / base-left at 3/4 h.
/// Reference: Section 4.2 -- S3 Triangle.
class TriangleShape extends BaseShape {
  /// Base offset from the top as a fraction of height. 0.75 puts the centroid
  /// at the vertical centre of the box (optical centring).
  static const double _baseY = 0.75;

  @override
  void paintShape(Canvas canvas, Size size, Paint paint) {
    final double baseY = size.height * _baseY;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, baseY)
      ..lineTo(0, baseY)
      ..close();
    canvas.drawPath(path, paint);
  }
}
