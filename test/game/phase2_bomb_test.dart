import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/config/level_config.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:dont_tap_that/game/game_state.dart';
import 'package:dont_tap_that/game/score_manager.dart';
import 'package:dont_tap_that/game/spawn_manager.dart';

/// Deterministic Random for testing (mirrors spawn_manager_test's helper).
class _FixedRandom implements Random {
  final List<int> _ints;
  final List<double> _doubles;
  int _i = 0;
  int _d = 0;
  _FixedRandom({List<int> ints = const [0], List<double> doubles = const [0.5]})
      : _ints = ints,
        _doubles = doubles;
  @override
  int nextInt(int max) => _ints[_i++ % _ints.length] % max;
  @override
  double nextDouble() => _doubles[_d++ % _doubles.length];
  @override
  bool nextBool() => false;
}

/// Config with bombChance 1.0 so every non-guaranteed slot is a bomb.
const _bombConfig = LevelConfig(
  fallSpeed: 200,
  spawnRate: 1.0,
  maxObjects: 8,
  shapes: [ShapeType.circle, ShapeType.square, ShapeType.triangle],
  forbiddenChanges: false,
  forbiddenInterval: 0,
  idleDecaySeconds: 4.0,
  objectSize: 44,
  waveSize: 5,
  objectLifetime: 2.0,
  roundDuration: 60.0,
  bombChance: 1.0,
);

void main() {
  group('Phase 2 — Bomb spawning (§5)', () {
    test('bombs fill non-guaranteed slots and are never the forbidden shape', () {
      final manager = SpawnManager(
        config: _bombConfig,
        forbiddenShape: ShapeType.square,
        random: _FixedRandom(),
      );

      // Post-warmup overdue wave: slot 0 is the guaranteed forbidden, the rest
      // are bombs (bombChance == 1.0).
      final wave = manager.tickWave(13.0);
      expect(wave.length, _bombConfig.waveSize);

      final bombs = wave.where((d) => d.shapeType == ShapeType.bomb).toList();
      final forbidden = wave.where((d) => d.isForbidden).toList();

      expect(bombs.length, _bombConfig.waveSize - 1);
      expect(forbidden.length, 1, reason: 'exactly one guaranteed forbidden');

      for (final d in wave) {
        // A bomb is never flagged forbidden.
        if (d.shapeType == ShapeType.bomb) {
          expect(d.isForbidden, isFalse);
        }
        // Invariant still holds: forbidden iff shape == forbiddenShape.
        expect(d.isForbidden, equals(d.shapeType == ShapeType.square));
      }
    });

    test('ForbiddenManager never picks bomb (bomb is excluded from shape pools)', () {
      // Bomb is not in any LevelConfig.shapes, so it can never be selected.
      expect(_bombConfig.shapes.contains(ShapeType.bomb), isFalse);
    });
  });

  group('Phase 2 — ScoreManager.onPenaltyTap (time economy)', () {
    test('resets the combo to x1 WITHOUT deducting a life', () {
      final state = GameState();
      addTearDown(state.dispose);
      final sm = ScoreManager(state);

      sm.onCorrectTap(); // multiplier -> 2
      sm.onCorrectTap(); // multiplier -> 3
      expect(state.multiplier.value, greaterThan(1));
      expect(state.lives.value, 3);

      sm.onPenaltyTap();
      expect(state.multiplier.value, 1, reason: 'combo resets to x1');
      expect(state.lives.value, 3, reason: 'time economy: NO life loss');
    });

    test('onWrongTap still deducts a life (1.x / Zen path preserved)', () {
      final state = GameState();
      addTearDown(state.dispose);
      final sm = ScoreManager(state);

      sm.onWrongTap();
      expect(state.lives.value, 2);
      expect(state.multiplier.value, 1);
    });
  });
}
