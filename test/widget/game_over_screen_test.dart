import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dont_tap_that/screens/game_over_screen.dart';
import 'package:dont_tap_that/game/mock_game_controller.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('GameOverScreen renders and shows accuracy and score animation', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = MockGameController();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => GameOverScreen(prefs: prefs),
            settings: RouteSettings(
              arguments: {
                'score': 120,
                'controller': controller,
                'accuracy': 87.5,
                'longestStreak': 12,
              },
            ),
          );
        },
      ),
    );

    // Find the score text by its specific font size (64.0) to avoid conflict with BEST score (120)
    final scoreFinder = find.byWidgetPredicate((widget) =>
        widget is Text && widget.style?.fontSize == 64.0);
    expect(scoreFinder, findsOneWidget);

    // Initial value is 0
    expect(tester.widget<Text>(scoreFinder).data, "0");

    // Pump to process microtasks and enable the timer
    await tester.pump();

    // Renders GAME OVER
    expect(find.text("GAME OVER"), findsOneWidget);

    // Accuracy shows 87.5%
    expect(find.text("87.5%"), findsOneWidget);

    // RETRY button is disabled on first render
    final retryFinder = find.widgetWithText(ElevatedButton, "RETRY");
    expect(tester.widget<ElevatedButton>(retryFinder).enabled, isFalse);

    // Wait 1 second for the timer to enable RETRY button
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<ElevatedButton>(retryFinder).enabled, isTrue);

    // Let the animation complete (600 ms)
    await tester.pump(const Duration(milliseconds: 600));
    final finalScoreText = tester.widget<Text>(scoreFinder).data;
    expect(finalScoreText, "120");
  });

  testWidgets('Accuracy shows em dash when accuracy is null', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = MockGameController();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => GameOverScreen(prefs: prefs),
            settings: RouteSettings(
              arguments: {
                'score': 120,
                'controller': controller,
                'accuracy': null,
                'longestStreak': 12,
              },
            ),
          );
        },
      ),
    );

    await tester.pump();
    expect(find.text("—"), findsOneWidget);
  });
}
