import 'dart:math';
import 'package:flame/extensions.dart';
import '../config/level_config.dart';
import '../config/shape_type.dart';

/// Manages forbidden shape selection and proximity logic.
///
/// Reference: Section 2.5, Section 5.2, FR-15, FR-19.
class ForbiddenManager {
  static ShapeType selectForbidden({
    required LevelConfig config,
    ShapeType? previousForbidden,
    Random? random,
  }) {
    final rand = random ?? Random();
    final shapes = config.shapes;
    if (shapes.isEmpty) {
      throw StateError("LevelConfig.shapes cannot be empty");
    }
    if (previousForbidden != null && shapes.length > 1) {
      final candidates = shapes.where((s) => s != previousForbidden).toList();
      return candidates[rand.nextInt(candidates.length)];
    }
    return shapes[rand.nextInt(shapes.length)];
  }

  /// Checks if a tap position is within the proximity threshold of a forbidden object's center.
  ///
  /// Reference: FR-15, Section 4.5.
  static bool isWithinProximity(
    Vector2 tapPosition,
    Vector2 forbiddenPosition, {
    double proximityRadius = 80.0,
  }) {
    return tapPosition.distanceTo(forbiddenPosition) <= proximityRadius;
  }
}
