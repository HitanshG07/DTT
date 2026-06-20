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
    controller.state.lives.value = 2;
    controller.state.multiplier.value = 3; // > 1 -> combo decay badge renders
    controller.state.decayProgress.value = 0.5;
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
}
