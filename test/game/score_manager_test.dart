import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/config/game_constants.dart';
import 'package:dont_tap_that/game/game_state.dart';
import 'package:dont_tap_that/game/score_manager.dart';

void main() {
  late GameState state;
  late ScoreManager manager;

  setUp(() {
    state = GameState();
    manager = ScoreManager(state);
  });

  tearDown(() {
    state.dispose();
  });

  group('ScoreManager', () {
    test('score increases by kBasePoints * multiplier on first correct tap', () {
      // With kComboThreshold = 1, first correct tap increments multiplier
      // from 1 to 2 BEFORE calculating points, so score = 10 * 2 = 20.
      manager.onCorrectTap();
      expect(state.score.value, equals(GameConstants.kScorePerTap * 2));
    });

    test('score increases correctly after combo threshold reached', () {
      // First correct tap: consecutive reaches 1 >= kComboThreshold(1),
      // multiplier goes to 2. points = 10 * 2 = 20.
      manager.onCorrectTap();
      expect(state.score.value, equals(20));
      expect(state.multiplier.value, equals(2));

      // Second correct tap: consecutive reaches 1 >= 1,
      // multiplier goes to 3. points = 10 * 3 = 30. Total = 50.
      manager.onCorrectTap();
      expect(state.score.value, equals(50));
      expect(state.multiplier.value, equals(3));
    });

    test('wrong tap decrements lives by 1', () {
      final int livesBefore = state.lives.value;
      manager.onWrongTap();
      expect(state.lives.value, equals(livesBefore - 1));
    });

    test('wrong tap resets combo to x1 (FR-06)', () {
      // Build some combo.
      manager.onCorrectTap();
      manager.onCorrectTap();
      expect(state.multiplier.value, greaterThan(1));

      // Forbidden tap resets multiplier all the way to x1, not by one step.
      manager.onWrongTap();
      expect(state.multiplier.value, equals(1));
    });

    test('missed object does NOT decrement lives', () {
      final int livesBefore = state.lives.value;
      manager.onMissed(false);
      expect(state.lives.value, equals(livesBefore));
    });

    test('missed correct object drops combo multiplier by one step (FR-06)', () {
      // Build multiplier to 3 (two correct taps with kComboThreshold = 1).
      manager.onCorrectTap();
      manager.onCorrectTap();
      expect(state.multiplier.value, equals(3));

      manager.onMissed(false);
      expect(state.multiplier.value, equals(2));
    });

    test('missed forbidden object does NOT affect combo', () {
      manager.onCorrectTap();
      manager.onCorrectTap();
      final int multiplierBefore = state.multiplier.value;

      // Letting the forbidden shape fall off is the desired play -- no penalty.
      manager.onMissed(true);
      expect(state.multiplier.value, equals(multiplierBefore));
    });

    test('getAccuracyPercent returns null when totalTapped == 0', () {
      expect(manager.getAccuracyPercent(), isNull);
    });

    test('getAccuracyPercent returns 100.0 after 3 correct, 0 wrong taps', () {
      manager.onCorrectTap();
      manager.onCorrectTap();
      manager.onCorrectTap();
      expect(manager.getAccuracyPercent(), equals(100.0));
    });

    test('getAccuracyPercent returns ~66.7 after 2 correct, 1 wrong', () {
      manager.onCorrectTap();
      manager.onCorrectTap();
      manager.onWrongTap();
      final accuracy = manager.getAccuracyPercent()!;
      expect(accuracy, closeTo(66.7, 0.1));
    });

    test('idle decay: after idleDecaySeconds tick, multiplier drops by 1', () {
      // Build multiplier to 2.
      manager.onCorrectTap();
      expect(state.multiplier.value, equals(2));

      // Tick past idle decay threshold.
      manager.tick(GameConstants.kIdleDecaySeconds);
      expect(state.multiplier.value, equals(1));
    });

    test('longestStreak tracked correctly across correct/wrong tap sequence', () {
      // 3 correct taps (streak = 3).
      manager.onCorrectTap();
      manager.onCorrectTap();
      manager.onCorrectTap();
      expect(manager.longestStreak, equals(3));

      // Wrong tap resets current streak.
      manager.onWrongTap();

      // 2 more correct taps (streak = 2, longest stays 3).
      manager.onCorrectTap();
      manager.onCorrectTap();
      expect(manager.longestStreak, equals(3));
    });
  });

  group('ScoreManager — Frenzy Mode (Feature M)', () {
    test('onCorrectTap returns the points it awarded', () {
      // First tap takes the multiplier to 2 → 10 * 2 = 20.
      final awarded = manager.onCorrectTap();
      expect(awarded, GameConstants.kScorePerTap * 2);
      expect(awarded, state.score.value);
    });

    test('frenzy doubles correct-tap points (and the returned value)', () {
      manager.startFrenzy();
      expect(manager.isFrenzyActive, isTrue);

      // mult → 2, frenzy ×2 → 10 * 2 * 2 = 40.
      final awarded = manager.onCorrectTap();
      expect(
        awarded,
        GameConstants.kScorePerTap * GameConstants.kFrenzyScoreMultiplier * 2,
      );
      expect(state.score.value, 40);
    });

    test('frenzy auto-ends after kFrenzyDurationSeconds via tick', () {
      manager.startFrenzy();
      manager.tick(GameConstants.kFrenzyDurationSeconds);
      expect(manager.isFrenzyActive, isFalse);
    });

    test('endFrenzy clears immediately and points stop doubling', () {
      manager.startFrenzy();
      manager.endFrenzy();
      expect(manager.isFrenzyActive, isFalse);

      // mult → 2, NOT doubled → 20.
      final awarded = manager.onCorrectTap();
      expect(awarded, GameConstants.kScorePerTap * 2);
    });

    test('INTEGRITY: penalty still fully resets the combo during frenzy', () {
      manager.startFrenzy();
      manager.onCorrectTap();
      manager.onCorrectTap();
      expect(state.multiplier.value, greaterThan(1));

      // Bomb/forbidden share onPenaltyTap — frenzy must not soften it.
      manager.onPenaltyTap();
      expect(state.multiplier.value, 1);
      expect(manager.isFrenzyActive, isTrue, reason: 'penalty does not end frenzy');
    });
  });
}