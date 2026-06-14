import 'dart:ui';

import '../config/shape_type.dart';
import 'circle_shape.dart';
import 'cross_shape.dart';
import 'diamond_shape.dart';
import 'pentagon_shape.dart';
import 'square_shape.dart';
import 'star_shape.dart';
import 'triangle_shape.dart';

/// Abstract base for all shape painters.
///
/// Each shape draws itself onto a [Canvas] within the given [size].
/// Shapes use [size.width] and [size.height] to stay proportional --
/// no hardcoded pixel values. White fill (kPrimaryText = #F2F2F2) by
/// default; the caller supplies the [Paint].
///
/// Tap hitbox logic lives in FallingObject (Stage 3), not here.
/// Zero Flame imports. Zero Flutter widget imports. Pure dart:ui.
///
/// Reference: Section 4.2, Section 7.2.
abstract class BaseShape {
  /// Draws this shape onto [canvas] within the given [size] using [paint].
  void paintShape(Canvas canvas, Size size, Paint paint);

  /// Factory that returns the concrete painter for the given [type].
  static BaseShape forType(ShapeType type) {
    switch (type) {
      case ShapeType.circle:
        return CircleShape();
      case ShapeType.square:
        return SquareShape();
      case ShapeType.triangle:
        return TriangleShape();
      case ShapeType.pentagon:
        return PentagonShape();
      case ShapeType.star:
        return StarShape();
      case ShapeType.diamond:
        return DiamondShape();
      case ShapeType.cross:
        return CrossShape();
    }
  }
}
