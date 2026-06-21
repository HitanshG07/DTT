import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dont_tap_that/game/dtt_game.dart';
import 'package:dont_tap_that/game/real_game_controller.dart';
import 'package:dont_tap_that/game/config/checkpoint_spec.dart';
import 'package:dont_tap_that/game/config/level_config.dart';

/// Phase 4A note: forbidden rotation is config-driven and (in the generated
/// curve) only turns on from L13. These integration tests exercise the rotation
/// **engine**, so they build an explicit rotating config via [_rotating] rather
/// than relying on a particular level number. `roundDuration` is large so the
/// burst round timer never cuts a rotation, and checkpoints are disabled (a
/// checkpoint would pause the game waiting for a recall answer).
LevelConfig _rotating(LevelConfig base, {required int interval}) => base.copyWith(
      forbiddenChanges: true,
      forbiddenInterval: interval,
      roundDuration: 300.0,
      checkpoint: const CheckpointSpec(),
    );

void main() {
  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

  group('Stage 6: Forbidden Change Integration Tests', () {
    late RealGameController controller;

    setUp(() {
      controller = RealGameController(level: 4);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('interval-30 config fires once at exactly 30 s after warmup', (WidgetTester tester) async {
      final game = DttGame(
        controller: controller,
        levelConfig: _rotating(controller.levelConfig, interval: 30),
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

      // 4. interval==30 changes ONCE only. Pump another 30 s; it must not change again.
      await tester.pump(const Duration(seconds: 30));
      expect(controller.state.forbiddenShape.value, equals(newForbidden),
          reason: 'interval-30 forbidden shape should only change once per round');
    });

    testWidgets('interval-20 config fires periodically at 20 s, 40 s, 60 s', (WidgetTester tester) async {
      final game = DttGame(
        controller: controller,
        levelConfig: _rotating(controller.levelConfig, interval: 20),
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

      // 2. First 20s tick
      await tester.pump(const Duration(seconds: 20));
      var nextForbidden = controller.state.forbiddenShape.value;
      expect(nextForbidden, isNot(equals(currentForbidden)),
          reason: 'First change should fire at 20s');
      currentForbidden = nextForbidden;

      // 3. Second 20s tick
      await tester.pump(const Duration(seconds: 20));
      nextForbidden = controller.state.forbiddenShape.value;
      expect(nextForbidden, isNot(equals(currentForbidden)),
          reason: 'Second change should fire at 40s');
      currentForbidden = nextForbidden;

      // 4. Third 20s tick
      await tester.pump(const Duration(seconds: 20));
      nextForbidden = controller.state.forbiddenShape.value;
      expect(nextForbidden, isNot(equals(currentForbidden)),
          reason: 'Third change should fire at 60s');
    });

    testWidgets('Change does not fire while game is paused', (WidgetTester tester) async {
      final game = DttGame(
        controller: controller,
        levelConfig: _rotating(controller.levelConfig, interval: 30),
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

      // Now pump the remaining time to complete the 30s interval.
      await tester.pump(const Duration(seconds: 30));

      expect(controller.state.forbiddenShape.value, isNot(equals(initialForbidden)),
          reason: 'Forbidden change should fire after resuming and completing the required duration');
    });

    testWidgets('No-repeat rule: new forbidden shape differs from the previous shape', (WidgetTester tester) async {
      final game = DttGame(
        controller: controller,
        levelConfig: _rotating(controller.levelConfig, interval: 20),
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

      var previousForbidden = controller.state.forbiddenShape.value!;

      // Bypass warmup.
      await tester.pump(const Duration(seconds: 12));

      // roundDuration is 300s here, so all rotations fall inside the round.
      for (int i = 0; i < 3; i++) {
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
        levelConfig: _rotating(controller.levelConfig, interval: 30),
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
