import 'package:dont_tap_that/game/config/level_generator.dart';
import 'package:dont_tap_that/game/config/level_registry.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:dont_tap_that/game/config/star_thresholds.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 4A: the registry is now generated (sawtooth curve + flavors + caps).
/// We assert **curve invariants** rather than hand-typed magic numbers.
void main() {
  group('LevelRegistry (generated, 30 levels)', () {
    test('there are exactly 30 levels', () {
      expect(LevelRegistry.levelCount, 30);
      expect(LevelRegistry.levels.length, 30);
    });

    test('forLevel clamps out-of-range to [1, 30]', () {
      expect(LevelRegistry.forLevel(0).objectSize,
          LevelRegistry.forLevel(1).objectSize);
      expect(LevelRegistry.forLevel(99).objectSize,
          LevelRegistry.forLevel(30).objectSize);
    });

    test('L1 is the easiest, L30 the hardest (endpoints)', () {
      final l1 = LevelRegistry.forLevel(1);
      final l30 = LevelRegistry.forLevel(30);
      expect(l1.objectSize, greaterThan(l30.objectSize));
      expect(l1.shapes.length, 3);
      expect(l30.shapes.length, 7);
    });

    test('sawtooth: difficulty rises within a world but dips at world starts', () {
      // Within each world (5 levels) difficulty strictly increases...
      for (int w = 0; w < 6; w++) {
        for (int i = 0; i < 4; i++) {
          final a = LevelGenerator.difficultyFor(w * 5 + i + 1);
          final b = LevelGenerator.difficultyFor(w * 5 + i + 2);
          expect(b, greaterThan(a), reason: 'world $w level $i→${i + 1}');
        }
      }
      // ...but each new world starts easier than the previous world's peak.
      for (int w = 1; w < 6; w++) {
        final prevPeak = LevelGenerator.difficultyFor(w * 5); // last of prev world
        final newStart = LevelGenerator.difficultyFor(w * 5 + 1); // first of new
        expect(newStart, lessThan(prevPeak), reason: 'breather at world $w');
      }
    });

    test('object size is non-increasing within each world (size not flavored)', () {
      for (int w = 0; w < 6; w++) {
        for (int i = 0; i < 4; i++) {
          final a = LevelRegistry.forLevel(w * 5 + i + 1).objectSize;
          final b = LevelRegistry.forLevel(w * 5 + i + 2).objectSize;
          expect(b, lessThanOrEqualTo(a));
        }
      }
    });

    test('shape count is monotonic non-decreasing 3→7', () {
      int prev = 0;
      for (int n = 1; n <= 30; n++) {
        final c = LevelRegistry.forLevel(n).shapes.length;
        expect(c, greaterThanOrEqualTo(prev));
        expect(c, inInclusiveRange(3, 7));
        prev = c;
      }
      // bomb is never a normal shape in the pool.
      for (int n = 1; n <= 30; n++) {
        expect(LevelRegistry.forLevel(n).shapes.contains(ShapeType.bomb), isFalse);
      }
    });

    group('mechanic breakpoints', () {
      test('bombs only from L4', () {
        for (int n = 1; n <= 3; n++) {
          expect(LevelRegistry.forLevel(n).bombChance, 0.0, reason: 'L$n');
        }
        for (int n = 4; n <= 30; n++) {
          expect(LevelRegistry.forLevel(n).bombChance, greaterThan(0.0), reason: 'L$n');
        }
      });

      test('forbidden rotation only from L13', () {
        for (int n = 1; n <= 12; n++) {
          expect(LevelRegistry.forLevel(n).forbiddenChanges, isFalse, reason: 'L$n');
        }
        for (int n = 13; n <= 30; n++) {
          expect(LevelRegistry.forLevel(n).forbiddenChanges, isTrue, reason: 'L$n');
        }
      });

      test('checkpoints only from L9; order-recall only from L21', () {
        for (int n = 1; n <= 8; n++) {
          expect(LevelRegistry.forLevel(n).checkpoint.enabled, isFalse, reason: 'L$n');
        }
        for (int n = 9; n <= 30; n++) {
          final cp = LevelRegistry.forLevel(n).checkpoint;
          expect(cp.enabled, isTrue, reason: 'L$n');
          expect(cp.orderMatters, n >= 21, reason: 'L$n order');
        }
      });
    });

    group('human-possible hard caps (every level)', () {
      // Hotfix H raised the floors so the late campaign is human-clearable:
      // lifetime ≥ 1.7s, size 42–52px, ≤ 7 on-screen, waves ≤ 6.
      test('lifetime ≥ 1.7s, bomb ≤ 0.30, rotation ≥ 12s, recall ≤ 4, humane size/counts', () {
        for (int n = 1; n <= 30; n++) {
          final c = LevelRegistry.forLevel(n);
          expect(c.objectLifetime, greaterThanOrEqualTo(1.7), reason: 'L$n lifetime');
          expect(c.bombChance, lessThanOrEqualTo(0.30), reason: 'L$n bomb');
          if (c.forbiddenChanges) {
            expect(c.forbiddenInterval, greaterThanOrEqualTo(12), reason: 'L$n rot');
          }
          expect(c.checkpoint.recallCount, lessThanOrEqualTo(4), reason: 'L$n recall');
          expect(c.objectSize, inInclusiveRange(42, 52), reason: 'L$n size');
          expect(c.maxObjects, lessThanOrEqualTo(7), reason: 'L$n maxObjects');
          expect(c.waveSize, lessThanOrEqualTo(6), reason: 'L$n waveSize');
          expect(c.waveSize, lessThanOrEqualTo(c.maxObjects), reason: 'L$n wave≤max');
        }
      });
    });

    group('star thresholds', () {
      test('every level has ascending one<two<three cutoffs', () {
        for (int n = 1; n <= 30; n++) {
          final s = LevelRegistry.forLevel(n).starThresholds;
          expect(s.one, lessThan(s.two));
          expect(s.two, lessThan(s.three));
        }
      });

      test('starsFor maps score to the right tier', () {
        const s = StarThresholds(one: 100, two: 200, three: 300);
        expect(s.starsFor(50), 0);
        expect(s.starsFor(100), 1);
        expect(s.starsFor(250), 2);
        expect(s.starsFor(300), 3);
        expect(s.starsFor(999), 3);
      });

      test('override map wins over the generated baseline', () {
        const override = {5: StarThresholds(one: 1, two: 2, three: 3)};
        const gen = LevelGenerator(starOverrides: override);
        expect(gen.forLevel(5).starThresholds.one, 1);
        // a non-overridden level keeps the baseline (not 1/2/3).
        expect(gen.forLevel(6).starThresholds.one, isNot(1));
      });
    });
  });
}
