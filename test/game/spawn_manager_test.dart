import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/config/level_config.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:dont_tap_that/game/spawn_manager.dart';

/// A deterministic Random for testing.
class _FixedRandom implements Random {
  final List<int> _intSequence;
  final List<double> _doubleSequence;
  int _intIndex = 0;
  int _doubleIndex = 0;

  _FixedRandom({
    List<int> intSequence = const [0],
    List<double> doubleSequence = const [0.5],
  })  : _intSequence = intSequence,
        _doubleSequence = doubleSequence;

  @override
  int nextInt(int max) {
    final value = _intSequence[_intIndex % _intSequence.length] % max;
    _intIndex++;
    return value;
  }

  @override
  double nextDouble() {
    final value = _doubleSequence[_doubleIndex % _doubleSequence.length];
    _doubleIndex++;
    return value;
  }

  @override
  bool nextBool() => false;
}

/// Level 1 config for testing.
const _testConfig = LevelConfig(
  fallSpeed: 120,
  spawnRate: 0.5,
  maxObjects: 4,
  shapes: [ShapeType.circle, ShapeType.square, ShapeType.triangle],
  forbiddenChanges: false,
  forbiddenInterval: 0,
  idleDecaySeconds: 4.0,
  warmupDurationSeconds: 12,
  forbiddenGuaranteeInterval: 8,
  spawnOverlapRadius: 60,
  objectSize: 48,
);

void main() {
  group('SpawnManager', () {
    test('during warmup window: no forbidden shapes spawned (10 ticks)', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.circle,
        // Always picks index 0 which would be circle (forbidden),
        // but warmup should override this.
        random: _FixedRandom(intSequence: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      );

      // spawnInterval = 1/0.5 = 2.0s. Warmup = 12s.
      // Do 5 ticks of 2.0s each = 10s elapsed, all within warmup (< 12s).
      for (int i = 0; i < 5; i++) {
        final decision = manager.tick(2.0);
        if (decision.shouldSpawn) {
          expect(decision.isForbidden, isFalse,
              reason: 'Forbidden must not spawn during warmup');
          expect(decision.shapeType, isNot(ShapeType.circle),
              reason: 'Forbidden shape type must not be selected during warmup');
        }
      }
    });

    test('after warmup: forbidden spawns can occur', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.circle,
        // Always returns index 0 which maps to circle (the forbidden shape).
        random: _FixedRandom(intSequence: [0]),
      );

      // Fast-forward past warmup (12s). tick(13) accumulates 13s of spawn
      // time. spawnInterval = 2s, so 13/2 = 6 spawns queued. The first
      // spawn consumes one interval. secondsSinceLastForbidden = 13 >= 8,
      // so the first spawn post-warmup is forced forbidden by FR-19.
      final decision = manager.tick(13.0);
      expect(decision.shouldSpawn, isTrue);
      expect(decision.isForbidden, isTrue);
    });

    test('FR-19: after forbiddenGuaranteeInterval seconds, next spawn is forced forbidden', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.triangle,
        // Pick index 0 = circle (non-forbidden) on each spawn.
        random: _FixedRandom(intSequence: [0]),
      );

      // Fast-forward past warmup. The initial 13s tick triggers a spawn,
      // which is forced forbidden by FR-19 (13s > 8s guarantee).
      final first = manager.tick(13.0);
      expect(first.shouldSpawn, isTrue);
      expect(first.isForbidden, isTrue);
      expect(first.shapeType, equals(ShapeType.triangle));

      // Now spawn several non-forbidden objects.
      // Each 2.0s tick spawns one object. After 4 spawns (8s), the
      // guarantee interval is exceeded again.
      for (int i = 0; i < 3; i++) {
        manager.tick(2.0);
      }

      // At 6s since last forbidden, one more 2s tick = 8s total.
      final decision = manager.tick(2.0);
      expect(decision.shouldSpawn, isTrue);
      expect(decision.isForbidden, isTrue);
      expect(decision.shapeType, equals(ShapeType.triangle));
    });

    test('FR-20: generateX avoids positions within spawnOverlapRadius', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.circle,
        // First 9 doubles produce x near 35.2 (within overlap of 30).
        // 10th double produces x at 281.6 (far from 30).
        random: _FixedRandom(
          doubleSequence: [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.8],
        ),
      );

      // Game width = 400, objectSize = 48, maxX = 352.
      // Existing object at x=30. Overlap radius = 60.
      // 0.1 * 352 = 35.2, |35.2 - 30| = 5.2 < 60 -> rejected 9 times.
      // Fallback (10th attempt): 0.8 * 352 = 281.6, |281.6 - 30| > 60.
      final x = manager.generateX([30.0], 400.0);
      expect((x - 30.0).abs(), greaterThanOrEqualTo(_testConfig.spawnOverlapRadius));
    });

    test('spawn rate: tick accumulates correctly at given spawnRate', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.circle,
        random: _FixedRandom(intSequence: [1]),
      );

      // spawnRate = 0.5, so spawnInterval = 2.0 seconds.
      // A tick of 1.0s should NOT trigger a spawn.
      final d1 = manager.tick(1.0);
      expect(d1.shouldSpawn, isFalse);

      // Another 1.0s tick should trigger spawn (total 2.0s >= spawnInterval).
      final d2 = manager.tick(1.0);
      expect(d2.shouldSpawn, isTrue);
    });
  });
}