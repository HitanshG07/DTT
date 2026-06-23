import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/config/checkpoint_spec.dart';
import 'package:dont_tap_that/game/checkpoint_manager.dart';

const _spec = CheckpointSpec(
  enabled: true,
  interval: 20.0,
  specialsPerWindow: 3,
  recallCount: 3,
  orderMatters: false,
  distractorCount: 3,
  tokens: ['A', 'B', 'C', 'D', 'E', 'F'],
  rewardSeconds: 5.0,
  penaltySeconds: 3.0,
);

const _orderSpec = CheckpointSpec(
  enabled: true,
  interval: 15.0,
  specialsPerWindow: 3,
  recallCount: 3,
  orderMatters: true,
  distractorCount: 3,
  tokens: ['A', 'B', 'C', 'D', 'E', 'F'],
  rewardSeconds: 5.0,
  penaltySeconds: 3.0,
);

void main() {
  group('CheckpointManager', () {
    test('assignToken hands out distinct tokens up to specialsPerWindow', () {
      final m = CheckpointManager(spec: _spec, random: Random(1));
      final t1 = m.assignToken();
      final t2 = m.assignToken();
      final t3 = m.assignToken();
      final t4 = m.assignToken(); // window full -> null

      expect([t1, t2, t3], everyElement(isNotNull));
      expect({t1, t2, t3}.length, 3, reason: 'tokens are distinct');
      expect(t4, isNull);
      expect(m.windowTokens, hasLength(3));
    });

    test('disabled spec never assigns tokens and is never due', () {
      final m = CheckpointManager(
        spec: const CheckpointSpec(), // disabled
        random: Random(1),
      );
      expect(m.assignToken(), isNull);
      m.tick(100.0);
      expect(m.isDue, isFalse);
    });

    test('isDue only after the interval AND at least one special was shown', () {
      final m = CheckpointManager(spec: _spec, random: Random(1));
      m.tick(25.0); // past interval but nothing shown yet
      expect(m.isDue, isFalse, reason: 'nothing to recall');

      m.assignToken();
      expect(m.isDue, isTrue);
    });

    test('buildPrompt options contain every seen token and recallCount is set', () {
      final m = CheckpointManager(spec: _spec, random: Random(3));
      final a = m.assignToken()!;
      final b = m.assignToken()!;
      final c = m.assignToken()!;

      final prompt = m.buildPrompt();
      // Every shown token must be offered (no phantom-only options).
      expect(prompt.options, containsAll([a, b, c]));
      expect(prompt.seen, equals([a, b, c]));
      expect(prompt.recallCount, 3);
      // Options are unique and bounded (seen + up to distractorCount).
      expect(prompt.options.toSet().length, prompt.options.length);
      expect(prompt.options.length,
          lessThanOrEqualTo(_spec.specialsPerWindow + _spec.distractorCount));
    });

    test('set-recall: correct membership (any order) gives +reward, perfect, resets', () {
      final m = CheckpointManager(spec: _spec, random: Random(5));
      final seen = [m.assignToken()!, m.assignToken()!, m.assignToken()!];

      final out = m.resolve(seen.reversed.toList()); // order should NOT matter
      expect(out.timeDelta, _spec.rewardSeconds);
      expect(out.perfect, isTrue);
      expect(m.windowTokens, isEmpty, reason: 'window resets after resolve');
    });

    test('set-recall: wrong membership gives -penalty and is not perfect', () {
      final m = CheckpointManager(spec: _spec, random: Random(5));
      m.assignToken();
      m.assignToken();
      m.assignToken();
      // A token guaranteed not in the seen set (window holds 3 of 6).
      final wrong = _spec.tokens
          .where((t) => !m.windowTokens.contains(t))
          .take(3)
          .toList();

      final out = m.resolve(wrong);
      expect(out.timeDelta, -_spec.penaltySeconds);
      expect(out.perfect, isFalse);
    });

    test('order-recall: correct order rewards, wrong order penalises', () {
      final m1 = CheckpointManager(spec: _orderSpec, random: Random(7));
      final seen1 = [m1.assignToken()!, m1.assignToken()!, m1.assignToken()!];
      expect(m1.resolve(seen1).timeDelta, _orderSpec.rewardSeconds);

      final m2 = CheckpointManager(spec: _orderSpec, random: Random(7));
      final seen2 = [m2.assignToken()!, m2.assignToken()!, m2.assignToken()!];
      final out2 = m2.resolve(seen2.reversed.toList());
      expect(out2.timeDelta, -_orderSpec.penaltySeconds,
          reason: 'reversed order is wrong when orderMatters');
      expect(out2.perfect, isFalse);
    });

    test('round tally counts shown + perfect across windows (Feature M)', () {
      final m = CheckpointManager(spec: _spec, random: Random(9));
      // Window 1: aced.
      final w1 = [m.assignToken()!, m.assignToken()!, m.assignToken()!];
      m.resolve(w1);
      // Window 2: failed (a token not in the new window).
      m.assignToken();
      m.assignToken();
      m.assignToken();
      final wrong = _spec.tokens
          .where((t) => !m.windowTokens.contains(t))
          .take(3)
          .toList();
      m.resolve(wrong);

      expect(m.checkpointsShown, 2, reason: 'two checkpoints resolved');
      expect(m.checkpointsPerfect, 1, reason: 'only the first was aced');
    });

    test('memoryStarsFor: ratio tiers and the no-checkpoints case', () {
      expect(CheckpointManager.memoryStarsFor(0, 0), 0); // none shown
      expect(CheckpointManager.memoryStarsFor(3, 3), 3); // all aced
      expect(CheckpointManager.memoryStarsFor(3, 2), 2); // 2/3
      expect(CheckpointManager.memoryStarsFor(3, 1), 1); // 1/3
      expect(CheckpointManager.memoryStarsFor(3, 0), 0); // none aced
      expect(CheckpointManager.memoryStarsFor(4, 1), 0); // 0.25 < 1/3
    });
  });
}
