import 'package:dont_tap_that/game/config/level_registry.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelRegistry', () {
    test('forLevel(1) returns fallSpeed 120 and objectSize 48', () {
      final config = LevelRegistry.forLevel(1);
      expect(config.fallSpeed, 120);
      expect(config.objectSize, 48);
    });

    test('forLevel(5) returns fallSpeed 320 and objectSize 36', () {
      final config = LevelRegistry.forLevel(5);
      expect(config.fallSpeed, 320);
      expect(config.objectSize, 36);
    });

    test('forLevel(99) clamps to Level 5 (ceiling rule)', () {
      final config = LevelRegistry.forLevel(99);
      final level5 = LevelRegistry.forLevel(5);
      expect(config.fallSpeed, level5.fallSpeed);
      expect(config.objectSize, level5.objectSize);
      expect(config.maxObjects, level5.maxObjects);
      expect(config.spawnRate, level5.spawnRate);
    });

    test('forLevel(3).shapes contains ShapeType.star', () {
      final config = LevelRegistry.forLevel(3);
      expect(config.shapes, contains(ShapeType.star));
    });

    test('forLevel(0) clamps to Level 1', () {
      final config = LevelRegistry.forLevel(0);
      final level1 = LevelRegistry.forLevel(1);
      expect(config.fallSpeed, level1.fallSpeed);
    });

    test('Level 1 has 3 shape types', () {
      final config = LevelRegistry.forLevel(1);
      expect(config.shapes.length, 3);
    });

    test('Level 5 has 7 shape types (all shapes)', () {
      final config = LevelRegistry.forLevel(5);
      expect(config.shapes.length, 7);
    });

    test('Level 4 has forbiddenChanges true with 30 s interval', () {
      final config = LevelRegistry.forLevel(4);
      expect(config.forbiddenChanges, isTrue);
      expect(config.forbiddenInterval, 30);
    });

    test('Level 5 has forbiddenChanges true with 20 s interval', () {
      final config = LevelRegistry.forLevel(5);
      expect(config.forbiddenChanges, isTrue);
      expect(config.forbiddenInterval, 20);
    });

    test('Levels 1-3 have forbiddenChanges false', () {
      for (var level = 1; level <= 3; level++) {
        final config = LevelRegistry.forLevel(level);
        expect(config.forbiddenChanges, isFalse,
            reason: 'Level $level should not have forbidden changes');
      }
    });

    test('All levels have default warmupDurationSeconds of 12', () {
      for (var level = 1; level <= 5; level++) {
        final config = LevelRegistry.forLevel(level);
        expect(config.warmupDurationSeconds, 12);
      }
    });

    test('All levels have default idleDecaySeconds of 4.0', () {
      for (var level = 1; level <= 5; level++) {
        final config = LevelRegistry.forLevel(level);
        expect(config.idleDecaySeconds, 4.0);
      }
    });

    test('Level 2 spawnRate is 0.7 and maxObjects is 5', () {
      final config = LevelRegistry.forLevel(2);
      expect(config.spawnRate, 0.7);
      expect(config.maxObjects, 5);
    });

    test('Registry has exactly 5 levels', () {
      expect(LevelRegistry.levels.length, 5);
    });
  });
}
