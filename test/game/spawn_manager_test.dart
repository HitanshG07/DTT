import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/config/level_config.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:dont_tap_that/game/config/spawn_script.dart';
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

    test('FR-20: generateX falls back to center ± offset after 3 failed attempts', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.circle,
        // All random doubles will result in positions within the overlap zone (35.2).
        random: _FixedRandom(
          doubleSequence: [0.1, 0.1, 0.1, 0.5], // 3 attempts are 0.1, fallback uses 0.5
        ),
      );

      // Game width = 400, objectSize = 48, maxX = 352.
      // Center position = 400/2 - 48/2 = 176.
      // Fallback offset for 0.5 value = (0.5 - 0.5) * 40.0 = 0.
      // So center + offset = 176.
      final x = manager.generateX([30.0], 400.0);
      expect(x, equals(176.0));
    });

    test('a spawn is forbidden iff its shape equals the forbidden shape', () {
      // Cycle the random index across the whole pool so every shape gets
      // selected over many post-warmup ticks. Guards the desync where objects
      // were flagged forbidden independently of their shape.
      final manager = SpawnManager(
        config: _testConfig, // shapes: circle, square, triangle
        forbiddenShape: ShapeType.square,
        random: _FixedRandom(intSequence: [0, 1, 2]),
      );

      // Skip past the 12 s warmup (no forbidden spawns there).
      manager.tick(13.0);

      for (int i = 0; i < 30; i++) {
        final d = manager.tick(2.0);
        if (d.shouldSpawn) {
          expect(d.isForbidden, equals(d.shapeType == ShapeType.square),
              reason:
                  'isForbidden must match shapeType == forbiddenShape (got '
                  '${d.shapeType}, isForbidden=${d.isForbidden})');
        }
      }
    });
  });

  group('SpawnManager scripted (tutorial hook, Section 12.3)', () {
    SpawnManager scriptedManager(SpawnScript script,
        {ShapeType forbidden = ShapeType.square}) {
      return SpawnManager(
        config: _testConfig,
        forbiddenShape: forbidden,
        random: _FixedRandom(),
        script: script,
      );
    }

    test('emits each entry in order once its delay elapses', () {
      const script = SpawnScript([
        SpawnScriptEntry(delay: 1.0, shapeType: ShapeType.circle, x: 100.0),
        SpawnScriptEntry(delay: 2.0, shapeType: ShapeType.triangle, x: 200.0),
      ]);
      final manager = scriptedManager(script);

      // Before the first delay: no spawn.
      expect(manager.tick(0.5).shouldSpawn, isFalse);

      // First entry fires once 1.0s has accumulated.
      final first = manager.tick(0.5);
      expect(first.shouldSpawn, isTrue);
      expect(first.shapeType, equals(ShapeType.circle));
      expect(first.isForbidden, isFalse);
      expect(first.x, equals(100.0));

      // Second entry needs a fresh 2.0s after the first fired.
      expect(manager.tick(1.5).shouldSpawn, isFalse);
      final second = manager.tick(0.5);
      expect(second.shouldSpawn, isTrue);
      expect(second.shapeType, equals(ShapeType.triangle));
      expect(second.x, equals(200.0));
    });

    test('marks an entry forbidden when it matches the forbidden shape', () {
      const script = SpawnScript([
        SpawnScriptEntry(delay: 0.0, shapeType: ShapeType.square),
      ]);
      final manager = scriptedManager(script, forbidden: ShapeType.square);

      final decision = manager.tick(0.0);
      expect(decision.shouldSpawn, isTrue);
      expect(decision.isForbidden, isTrue);
    });

    test('skips once the script is exhausted', () {
      const script = SpawnScript([
        SpawnScriptEntry(delay: 0.0, shapeType: ShapeType.circle),
      ]);
      final manager = scriptedManager(script);

      expect(manager.tick(0.0).shouldSpawn, isTrue);
      // No further entries: every subsequent tick skips.
      expect(manager.tick(5.0).shouldSpawn, isFalse);
      expect(manager.tick(5.0).shouldSpawn, isFalse);
    });
  });

  group('SpawnManager wave mode (2.0 Burst, §4)', () {
    test('after warmup, tickWave emits exactly config.waveSize decisions (4-6)', () {
      final manager = SpawnManager(
        config: _testConfig, // waveSize defaults to 5
        forbiddenShape: ShapeType.square,
        random: _FixedRandom(intSequence: [0, 1, 2]),
      );

      // Skip warmup (12 s) and trigger a wave (spawnInterval = 2 s).
      final wave = manager.tickWave(13.0);
      expect(wave.length, equals(_testConfig.waveSize));
      expect(wave.length, inInclusiveRange(4, 6));
      for (final d in wave) {
        expect(d.shouldSpawn, isTrue);
      }
    });

    test('during warmup, tickWave emits at most one non-forbidden object', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.circle, // index 0 would pick circle
        random: _FixedRandom(intSequence: [0, 0, 0, 0]),
      );

      // Within warmup window; spawnInterval = 2 s.
      final wave = manager.tickWave(2.0);
      expect(wave.length, lessThanOrEqualTo(1));
      for (final d in wave) {
        expect(d.isForbidden, isFalse,
            reason: 'No forbidden objects may spawn during warmup');
        expect(d.shapeType, isNot(ShapeType.circle));
      }
    });

    test('every decision in a wave is forbidden iff its shape is the forbidden shape', () {
      final manager = SpawnManager(
        config: _testConfig, // shapes: circle, square, triangle
        forbiddenShape: ShapeType.square,
        random: _FixedRandom(intSequence: [0, 1, 2]),
      );

      // Drive several post-warmup waves so the random index cycles all shapes.
      manager.tickWave(13.0);
      for (int i = 0; i < 10; i++) {
        final wave = manager.tickWave(2.0);
        for (final d in wave) {
          expect(d.isForbidden, equals(d.shapeType == ShapeType.square),
              reason: 'isForbidden must match shapeType == forbiddenShape '
                  '(got ${d.shapeType}, isForbidden=${d.isForbidden})');
        }
      }
    });

    test('an overdue wave includes exactly one guaranteed forbidden (FR-19)', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.triangle,
        // index 0 = circle (non-forbidden) for every non-forced slot.
        random: _FixedRandom(intSequence: [0]),
      );

      // 13 s since start (> 8 s guarantee) -> first wave forces one forbidden.
      final wave = manager.tickWave(13.0);
      final forbiddenCount = wave.where((d) => d.isForbidden).length;
      expect(forbiddenCount, equals(1));
      expect(wave.first.shapeType, equals(ShapeType.triangle));
    });

    test('generate2DPosition avoids points within spawnOverlapRadius (FR-20, 2D)', () {
      final manager = SpawnManager(
        config: _testConfig, // spawnOverlapRadius = 60, objectSize = 48
        forbiddenShape: ShapeType.circle,
        // Attempt 1 lands near the existing point (rejected); attempt 2 is far.
        random: _FixedRandom(
          doubleSequence: [0.02, 0.02, 0.9, 0.9],
        ),
      );

      // Play area 400x400, maxX = maxY = 352. Existing object at (10, 10).
      // Attempt 1: (~7, ~7) -> within 60 of (10,10) -> rejected.
      // Attempt 2: (~317, ~317) -> far -> accepted.
      final (x, y) = manager.generate2DPosition([10.0], [10.0], 400.0, 400.0);
      final double dist =
          ((x - 10.0) * (x - 10.0) + (y - 10.0) * (y - 10.0));
      expect(dist, greaterThanOrEqualTo(60.0 * 60.0));
    });

    test('generate2DPosition keeps points inside the play rect with areaTop', () {
      final manager = SpawnManager(
        config: _testConfig,
        forbiddenShape: ShapeType.circle,
        random: _FixedRandom(doubleSequence: [0.5, 0.5]),
      );

      const double areaTop = 88.0;
      final (x, y) =
          manager.generate2DPosition([], [], 400.0, 300.0, areaTop: areaTop);
      expect(x, inInclusiveRange(0.0, 400.0 - _testConfig.objectSize));
      expect(y, inInclusiveRange(areaTop, areaTop + 300.0 - _testConfig.objectSize));
    });
  });
}