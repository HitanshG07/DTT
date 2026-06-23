import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dont_tap_that/screens/start_screen.dart';

void main() {
  // Ensure SharedPreferences mock is initialised
  SharedPreferences.setMockInitialValues({});

  testWidgets("StartScreen renders title 'DON'T TAP THAT', BEST score, and PLAY button", (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        home: StartScreen(prefs: prefs),
      ),
    );

    expect(find.text("DON'T TAP THAT"), findsOneWidget);
    expect(find.text("BEST"), findsOneWidget);
    expect(find.text("PLAY"), findsOneWidget);
  });

  testWidgets('PLAY button navigates to /map (2.0 Phase 4C-2)', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/start',
        routes: {
          '/start': (context) => StartScreen(prefs: prefs),
          '/map': (context) => const Scaffold(
                body: Text('MAP SCREEN'),
              ),
        },
      ),
    );

    // Tap PLAY button
    await tester.tap(find.text("PLAY"));
    await tester.pumpAndSettle();

    // Verify navigation to the level map occurred
    expect(find.text('MAP SCREEN'), findsOneWidget);
  });
}
