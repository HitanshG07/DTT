import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dont_tap_that/game/real_game_controller.dart';

/// Regression guard for the duplicate-ScoreManager bug: the controller must
/// expose accuracy/longestStreak from the SAME ScoreManager that handles taps,
/// so the Game Over screen shows real values (not "—" / 0).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RealGameController stats wiring', () {
    test('accuracy and longestStreak reflect taps on controller.scoreManager', () {
      final controller = RealGameController();

      // No taps yet -> accuracy is null (em dash on the end screen), streak 0.
      expect(controller.accuracy, isNull);
      expect(controller.longestStreak, equals(0));

      // 3 correct, 1 wrong -> 3/4 = 75% accuracy, longest streak 3.
      controller.scoreManager.onCorrectTap();
      controller.scoreManager.onCorrectTap();
      controller.scoreManager.onCorrectTap();
      controller.scoreManager.onWrongTap();

      expect(controller.accuracy, closeTo(75.0, 0.001));
      expect(controller.longestStreak, equals(3));

      controller.dispose();
    });
  });
}
