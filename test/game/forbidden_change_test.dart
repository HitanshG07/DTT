import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dont_tap_that/game/dtt_game.dart';
import 'package:dont_tap_that/game/real_game_controller.dart';

void main() {
  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

  group('Stage 6: Forbidden Change Integration Tests', () {
    late RealGameController controller;

    setUp(() {
      controller = RealGameController(level: 4); // Default to Level 4 config
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Level 4 timer fires at exactly 30 s elapsed after warmup', (WidgetTester tester) async {
      final game = DttGame(
        controller: controller,
        levelConfig: controller.levelConfig,
        correctColor: Colors.green,
        forbiddenColor: Colors.red,
        shapeColor: Colors.white,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWidget(game: game),
          ),
        ),
      );

      // Wait for onload/warmup/etc. to stabilize
      await tester.pump();

      final initialForbidden = controller.state.forbiddenShape.value;
      expect(initialForbidden, isNotNull);

      // 1. Advance through warmup window (12 seconds)
      await tester.pump(const Duration(seconds: 12));
      expect(controller.state.forbiddenShape.value, equals(initialForbidden),
          reason: 'Forbidden shape must not change during the warmup window');

      // 2. Advance 29 seconds (1 second before the 30s mark)
      await tester.pump(const Duration(seconds: 29));
      expect(controller.state.forbiddenShape.value, equals(initialForbidden),
          reason: 'Forbidden shape must not change before 30 seconds elapsed after warmup');

      // 3. Advance the final 1 second (hitting the 30s mark)
      await tester.pump(const Duration(seconds: 1));
      final newForbidden = controller.state.forbiddenShape.value;
      expect(newForbidden, isNot(equals(initialForbidden)),
          reason: 'Forbidden shape must change at exactly 30s elapsed after warmup');

      // 4. Level 4 changes ONCE only. Let's pump another 30 seconds and check it doesn't change again.
      await tester.pump(const Duration(seconds: 30));
      expect(controller.state.forbiddenShape.value, equals(newForbidden),
          reason: 'Level 4 forbidden shape should only change once per round');
    });

    testWidgets('Level 5 timer fires periodically at 20 s, 40 s, 60 s', (WidgetTester tester) async {
      // Re-initialize controller for Level 5
      controller.dispose();
      controller = RealGameController(level: 5);

      final game = DttGame(
        controller: controller,
        levelConfig: controller.levelConfig,
        correctColor: Colors.green,
        forbiddenColor: Colors.red,
        shapeColor: Colors.white,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWidget(game: game),
          ),
        ),
      );

      await tester.pump();

      var currentForbidden = controller.state.forbiddenShape.value;
      expect(currentForbidden, isNotNull);

      // 1. Warmup window (12 seconds)
      await tester.pump(const Duration(seconds: 12));
      expect(controller.state.forbiddenShape.value, equals(currentForbidden));

      // 2. First 20s tick (fires at 20s mark -> 12 + 20 = 32s total elapsed)
      await tester.pump(const Duration(seconds: 20));
      var nextForbidden = controller.state.forbiddenShape.value;
      expect(nextForbidden, isNot(equals(currentForbidden)),
          reason: 'First Level 5 change should fire at 20s');
      currentForbidden = nextForbidden;

      // 3. Second 20s tick (fires at 40s mark -> 12 + 40 = 52s total elapsed)
      await tester.pump(const Duration(seconds: 20));
      nextForbidden = controller.state.forbiddenShape.value;
      expect(nextForbidden, isNot(equals(currentForbidden)),
          reason: 'Second Level 5 change should fire at 40s');
      currentForbidden = nextForbidden;

      // 4. Third 20s tick (fires at 60s mark -> 12 + 60 = 72s total elapsed)
      await tester.pump(const Duration(seconds: 20));
      nextForbidden = controller.state.forbiddenShape.value;
      expect(nextForbidden, isNot(equals(currentForbidden)),
          reason: 'Third Level 5 change should fire at 60s');
    });

    testWidgets('Change does not fire while game is paused', (WidgetTester tester) async {
      final game = DttGame(
        controller: controller,
        levelConfig: controller.levelConfig,
        correctColor: Colors.green,
        forbiddenColor: Colors.red,
        shapeColor: Colors.white,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWidget(game: game),
          ),
        ),
      );

      await tester.pump();

      final initialForbidden = controller.state.forbiddenShape.value;

      // Warmup window (12 seconds)
      await tester.pump(const Duration(seconds: 12));

      // Pause the controller
      controller.pause();
      await tester.pump();

      // Pump 40 seconds (well past the 30s mark)
      await tester.pump(const Duration(seconds: 40));

      expect(controller.state.forbiddenShape.value, equals(initialForbidden),
          reason: 'Forbidden change must not fire while the game is paused');

      // Resume the controller
      controller.resume();
      await tester.pump();

      // Now pump the remaining time to complete the 30s interval (we had 0s accumulated after warmup when paused)
      await tester.pump(const Duration(seconds: 30));

      expect(controller.state.forbiddenShape.value, isNot(equals(initialForbidden)),
          reason: 'Forbidden change should fire after resuming and completing the required duration');
    });

    testWidgets('No-repeat rule: new forbidden shape differs from the previous shape', (WidgetTester tester) async {
      // Re-initialize controller for Level 5 to support multiple rotations
      controller.dispose();
      controller = RealGameController(level: 5);

      final game = DttGame(
        controller: controller,
        levelConfig: controller.levelConfig,
        correctColor: Colors.green,
        forbiddenColor: Colors.red,
        shapeColor: Colors.white,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWidget(game: game),
          ),
        ),
      );

      await tester.pump();

      // We will force several rotations and check that each one is different from the previous.
      var previousForbidden = controller.state.forbiddenShape.value!;

      // Bypass warmup manually or by pumping
      await tester.pump(const Duration(seconds: 12));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 20));
        final newForbidden = controller.state.forbiddenShape.value!;
        expect(newForbidden, isNot(equals(previousForbidden)),
            reason: 'Shape selected at rotation $i must be different from previous shape');
        previousForbidden = newForbidden;
      }
    });

    testWidgets('HUD ValueNotifier updates when forbidden shape changes', (WidgetTester tester) async {
      final game = DttGame(
        controller: controller,
        levelConfig: controller.levelConfig,
        correctColor: Colors.green,
        forbiddenColor: Colors.red,
        shapeColor: Colors.white,
      );

      bool notifierUpdated = false;
      controller.state.forbiddenShape.addListener(() {
        notifierUpdated = true;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWidget(game: game),
          ),
        ),
      );

      await tester.pump();
      expect(notifierUpdated, isTrue, reason: 'Notifier should fire on initial shape selection');
      notifierUpdated = false; // Reset flag

      // Warmup window
      await tester.pump(const Duration(seconds: 12));

      // Hitting the 30s change mark
      await tester.pump(const Duration(seconds: 30));
      expect(notifierUpdated, isTrue, reason: 'Notifier must fire on mid-round forbidden change');
    });
  });
}
