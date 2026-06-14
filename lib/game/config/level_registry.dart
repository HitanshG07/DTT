import 'level_config.dart';
import 'shape_type.dart';

/// Registry of all level configurations.
///
/// Values match Section 3.1 parameter table exactly.
/// Level 5 is the ceiling per Section 3.3 -- game runs indefinitely
/// at Level 5 config until lives reach 0.
///
/// Reference: Section 3.1, Section 3.3.
class LevelRegistry {
  LevelRegistry._();

  /// All five level configurations, 0-indexed internally.
  static const List<LevelConfig> levels = [
    // Level 1: Onboarding. Large shapes, easy recognition.
    LevelConfig(
      fallSpeed: 120,
      spawnRate: 0.5,
      maxObjects: 4,
      shapes: [ShapeType.circle, ShapeType.square, ShapeType.triangle],
      forbiddenChanges: false,
      forbiddenInterval: 0,
      idleDecaySeconds: 4.0,
      objectSize: 48,
    ),
    // Level 2: Pentagon added. Slight size reduction.
    LevelConfig(
      fallSpeed: 160,
      spawnRate: 0.7,
      maxObjects: 5,
      shapes: [
        ShapeType.circle,
        ShapeType.square,
        ShapeType.triangle,
        ShapeType.pentagon,
      ],
      forbiddenChanges: false,
      forbiddenInterval: 0,
      idleDecaySeconds: 4.0,
      objectSize: 46,
    ),
    // Level 3: Star added. Shapes noticeably smaller.
    LevelConfig(
      fallSpeed: 210,
      spawnRate: 1.0,
      maxObjects: 6,
      shapes: [
        ShapeType.circle,
        ShapeType.square,
        ShapeType.triangle,
        ShapeType.pentagon,
        ShapeType.star,
      ],
      forbiddenChanges: false,
      forbiddenInterval: 0,
      idleDecaySeconds: 4.0,
      objectSize: 42,
    ),
    // Level 4: Diamond added. Mid-round switch every 30 s.
    LevelConfig(
      fallSpeed: 260,
      spawnRate: 1.3,
      maxObjects: 7,
      shapes: [
        ShapeType.circle,
        ShapeType.square,
        ShapeType.triangle,
        ShapeType.pentagon,
        ShapeType.star,
        ShapeType.diamond,
      ],
      forbiddenChanges: true,
      forbiddenInterval: 30,
      idleDecaySeconds: 4.0,
      objectSize: 40,
    ),
    // Level 5: All 7 shapes. 25% smaller than L1. Switch every 20 s.
    LevelConfig(
      fallSpeed: 320,
      spawnRate: 1.6,
      maxObjects: 8,
      shapes: [
        ShapeType.circle,
        ShapeType.square,
        ShapeType.triangle,
        ShapeType.pentagon,
        ShapeType.star,
        ShapeType.diamond,
        ShapeType.cross,
      ],
      forbiddenChanges: true,
      forbiddenInterval: 20,
      idleDecaySeconds: 4.0,
      objectSize: 36,
    ),
  ];

  /// Returns the [LevelConfig] for the given 1-indexed [level].
  ///
  /// Clamps to Level 5 (the ceiling). Level 5 is the maximum difficulty;
  /// the game runs indefinitely at Level 5 config until lives reach 0.
  /// Reference: Section 3.3.
  static LevelConfig forLevel(int level) {
    final clamped = level.clamp(1, levels.length);
    return levels[clamped - 1];
  }
}
