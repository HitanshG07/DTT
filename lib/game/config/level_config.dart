import 'shape_type.dart';

/// Configuration for a single difficulty level.
///
/// All fields from Section 3.2 of the planning document. Immutable.
/// [objectSize] controls visual rendering only -- tap hitbox is always
/// max(objectSize, 48) as defined in Section 3.3.
///
/// Reference: Section 3.2 -- LevelConfig Class (Dart).
class LevelConfig {
  /// Fall speed in logical pixels per second.
  final double fallSpeed;

  /// Objects spawned per second.
  final double spawnRate;

  /// Maximum concurrent objects on screen, bounded by pool size.
  final int maxObjects;

  /// Shape types available at this level.
  final List<ShapeType> shapes;

  /// Whether the forbidden shape changes mid-round.
  final bool forbiddenChanges;

  /// Seconds between forbidden shape changes (only relevant when
  /// [forbiddenChanges] is true).
  final int forbiddenInterval;

  /// Seconds of no tapping before combo multiplier drops by 1 step.
  /// Reference: Section 2.3 -- idle decay.
  final double idleDecaySeconds;

  /// Duration of the warmup window in seconds.
  /// During warmup: max 2 objects, no forbidden spawns.
  /// Reference: Section 2.6 / FR-18.
  final int warmupDurationSeconds;

  /// Forbidden shape must appear at least once within this interval
  /// in seconds. If not spawned naturally, the next spawn is forced.
  /// Reference: FR-19.
  final int forbiddenGuaranteeInterval;

  /// Minimum distance in logical pixels between newly spawned objects
  /// and existing active objects. Reference: FR-20.
  final double spawnOverlapRadius;

  /// Visual size of objects in logical pixels. Shrinks across levels
  /// (48 at Level 1 to 36 at Level 5). Tap hitbox is always >= 48 px.
  /// Reference: Section 3.1 parameter table, Section 4.2.
  final int objectSize;

  const LevelConfig({
    required this.fallSpeed,
    required this.spawnRate,
    required this.maxObjects,
    required this.shapes,
    required this.forbiddenChanges,
    required this.forbiddenInterval,
    required this.idleDecaySeconds,
    this.warmupDurationSeconds = 12,
    this.forbiddenGuaranteeInterval = 8,
    this.spawnOverlapRadius = 60,
    required this.objectSize,
  });
}
