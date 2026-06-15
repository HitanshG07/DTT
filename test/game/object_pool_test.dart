import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/config/game_constants.dart';
import 'package:dont_tap_that/game/config/level_config.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:dont_tap_that/game/components/falling_object.dart';
import 'package:dont_tap_that/game/object_pool.dart';

/// Level 1 config for testing.
const _testConfig = LevelConfig(
  fallSpeed: 120,
  spawnRate: 0.5,
  maxObjects: 4,
  shapes: [ShapeType.circle, ShapeType.square, ShapeType.triangle],
  forbiddenChanges: false,
  forbiddenInterval: 0,
  idleDecaySeconds: 4.0,
  objectSize: 48,
);

void main() {
  group('ObjectPool', () {
    late ObjectPool pool;

    setUp(() {
      pool = ObjectPool(
        poolSize: GameConstants.kMaxPoolSize,
        createObject: (index) => FallingObject(
          shapeType: ShapeType.circle,
          isForbidden: false,
          levelConfig: _testConfig,
          correctColor: const Color(0xFF22C55E),
          forbiddenColor: const Color(0xFFEF4444),
          onCorrectTap: (_) {},
          onWrongTap: (_) {},
          onMissed: (_) {},
        ),
      );
    });

    test('acquire returns non-null when pool has free slots', () {
      final obj = pool.acquire();
      expect(obj, isNotNull);
    });

    test('acquire returns null when pool is exhausted', () {
      // Exhaust the entire pool.
      for (int i = 0; i < GameConstants.kMaxPoolSize; i++) {
        expect(pool.acquire(), isNotNull);
      }

      // Pool is exhausted.
      expect(pool.acquire(), isNull);
    });

    test('release makes slot available again for acquire', () {
      // Exhaust the pool.
      final List<FallingObject> objects = [];
      for (int i = 0; i < GameConstants.kMaxPoolSize; i++) {
        objects.add(pool.acquire()!);
      }
      expect(pool.acquire(), isNull);

      // Release one object.
      pool.release(objects.first);

      // Now acquire should return non-null.
      expect(pool.acquire(), isNotNull);
    });

    test('pool size matches kMaxPoolSize after construction', () {
      expect(pool.poolSize, equals(GameConstants.kMaxPoolSize));
    });
  });
}