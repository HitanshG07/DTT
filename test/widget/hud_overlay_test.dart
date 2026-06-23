import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dont_tap_that/constants/app_sizes.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:dont_tap_that/game/real_game_controller.dart';
import 'package:dont_tap_that/overlays/hud_overlay.dart';

/// Regression guard for the "BOTTOM OVERFLOWED" HUD bug: the HUD bar must fit
/// its content (score + combo decay badge + forbidden thumbnail + AVOID label)
/// within kHudHeight with the combo badge visible (multiplier > 1).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HudOverlay does not overflow at kHudHeight with combo badge shown',
      (WidgetTester tester) async {
    final controller = RealGameController();
    controller.state.score.value = 120;
    controller.state.multiplier.value = 3; // > 1 -> combo decay badge renders
    controller.state.decayProgress.value = 0.5;
    controller.state.timeRemaining.value = 65.0; // 1:05 on the countdown
    controller.state.forbiddenShape.value = ShapeType.circle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: AppSizes.kHudHeight,
            child: HudOverlay(controller: controller),
          ),
        ),
      ),
    );

    // A RenderFlex overflow surfaces as a FlutterError during layout.
    expect(tester.takeException(), isNull);

    controller.dispose();
  });

  testWidgets('HudOverlay shows the round-time countdown (mm:ss), not hearts',
      (WidgetTester tester) async {
    final controller = RealGameController();
    controller.state.timeRemaining.value = 65.0; // -> "1:05"
    controller.state.forbiddenShape.value = ShapeType.circle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: AppSizes.kHudHeight,
            child: HudOverlay(controller: controller),
          ),
        ),
      ),
    );

    // Time economy: the countdown renders, lives/hearts are gone.
    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(tester.takeException(), isNull);

    controller.dispose();
  });
}
