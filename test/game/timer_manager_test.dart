import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/game_state.dart';
import 'package:dont_tap_that/game/timer_manager.dart';

void main() {
  group('TimerManager', () {
    late GameState state;

    setUp(() {
      state = GameState();
    });

    tearDown(() {
      state.dispose();
    });

    test('seeds GameState.timeRemaining to roundDuration on construction', () {
      final timer = TimerManager(state: state, roundDuration: 30.0);
      expect(timer.remaining, 30.0);
      expect(state.timeRemaining.value, 30.0);
      expect(timer.isExpired, isFalse);
    });

    test('tick decrements remaining and writes it to GameState', () {
      final timer = TimerManager(state: state, roundDuration: 10.0);
      timer.tick(3.0);
      expect(timer.remaining, closeTo(7.0, 1e-9));
      expect(state.timeRemaining.value, closeTo(7.0, 1e-9));
    });

    test('clamps at 0 and reports expired (never goes negative)', () {
      final timer = TimerManager(state: state, roundDuration: 5.0);
      timer.tick(8.0);
      expect(timer.remaining, 0.0);
      expect(state.timeRemaining.value, 0.0);
      expect(timer.isExpired, isTrue);
    });

    test('tick is a no-op once already expired', () {
      final timer = TimerManager(state: state, roundDuration: 2.0);
      timer.tick(5.0);
      expect(timer.isExpired, isTrue);
      timer.tick(5.0); // must not drive it negative or throw
      expect(timer.remaining, 0.0);
    });

    test('addTime adds and subtracts, clamping at 0 (Phase 2/3 economy hook)', () {
      final timer = TimerManager(state: state, roundDuration: 10.0);
      timer.addTime(5.0); // +5
      expect(timer.remaining, 15.0);
      expect(state.timeRemaining.value, 15.0);
      timer.addTime(-100.0); // over-subtract clamps to 0
      expect(timer.remaining, 0.0);
      expect(state.timeRemaining.value, 0.0);
    });
  });
}
