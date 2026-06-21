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

    test('set-recall: correct membership (any order) gives +reward and resets', () {
      final m = CheckpointManager(spec: _spec, random: Random(5));
      final seen = [m.assignToken()!, m.assignToken()!, m.assignToken()!];

      final delta = m.resolve(seen.reversed.toList()); // order should NOT matter
      expect(delta, _spec.rewardSeconds);
      expect(m.windowTokens, isEmpty, reason: 'window resets after resolve');
    });

    test('set-recall: wrong membership gives -penalty', () {
      final m = CheckpointManager(spec: _spec, random: Random(5));
      m.assignToken();
      m.assignToken();
      m.assignToken();
      // A token guaranteed not in the seen set (window holds 3 of 6).
      final wrong = _spec.tokens
          .where((t) => !m.windowTokens.contains(t))
          .take(3)
          .toList();

      expect(m.resolve(wrong), -_spec.penaltySeconds);
    });

    test('order-recall: correct order rewards, wrong order penalises', () {
      final m1 = CheckpointManager(spec: _orderSpec, random: Random(7));
      final seen1 = [m1.assignToken()!, m1.assignToken()!, m1.assignToken()!];
      expect(m1.resolve(seen1), _orderSpec.rewardSeconds);

      final m2 = CheckpointManager(spec: _orderSpec, random: Random(7));
      final seen2 = [m2.assignToken()!, m2.assignToken()!, m2.assignToken()!];
      expect(m2.resolve(seen2.reversed.toList()), -_orderSpec.penaltySeconds,
          reason: 'reversed order is wrong when orderMatters');
    });
  });
}
