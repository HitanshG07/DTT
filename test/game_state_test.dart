import 'package:dont_tap_that/game/config/game_constants.dart';
import 'package:dont_tap_that/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
    });

    tearDown(() {
      gameState.dispose();
    });

    test('initial score is 0', () {
      expect(gameState.score.value, 0);
    });

    test('initial lives is kLives (3)', () {
      expect(gameState.lives.value, GameConstants.kLives);
      expect(gameState.lives.value, 3);
    });

    test('initial multiplier is 1', () {
      expect(gameState.multiplier.value, 1);
    });

    test('initial decayProgress is 1.0', () {
      expect(gameState.decayProgress.value, 1.0);
    });

    test('initial forbiddenShape is null', () {
      expect(gameState.forbiddenShape.value, isNull);
    });

    test('dispose() does not throw', () {
      final state = GameState();
      expect(() => state.dispose(), returnsNormally);
    });

    // Regression (run2.log): GameScreen used to call state.dispose() AND
    // controller.dispose() (which also disposes state), throwing "A
    // ValueNotifier was used after being disposed". dispose() is now idempotent.
    test('dispose() is idempotent — calling twice does not throw', () {
      final state = GameState();
      state.dispose();
      expect(() => state.dispose(), returnsNormally);
    });

    test('notifiers can be updated', () {
      gameState.score.value = 100;
      gameState.lives.value = 2;
      gameState.multiplier.value = 3;
      gameState.decayProgress.value = 0.5;

      expect(gameState.score.value, 100);
      expect(gameState.lives.value, 2);
      expect(gameState.multiplier.value, 3);
      expect(gameState.decayProgress.value, 0.5);
    });
  });
}
