import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dont_tap_that/constants/debug_flags.dart';
import 'package:dont_tap_that/screens/map_screen.dart';
import 'package:dont_tap_that/services/progress_service.dart';

/// Phase 4C-2 — the map node tap must launch `/forbidden-intro` for the tapped
/// level, passing the 1-indexed level as a route argument.
void main() {
  group('Map navigation flow (2.0 Phase 4C-2)', () {
    testWidgets('tapping an unlocked node routes to /forbidden-intro with its level',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      Object? capturedArgs;

      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(progressService: ProgressService()),
          onGenerateRoute: (settings) {
            if (settings.name == '/forbidden-intro') {
              capturedArgs = settings.arguments;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('INTRO STUB')),
              );
            }
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Level 1 is always unlocked; tapping it launches the intro for level 1.
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(find.text('INTRO STUB'), findsOneWidget);
      expect(capturedArgs, isA<Map>());
      expect((capturedArgs as Map)['level'], 1);
    }, skip: DebugFlags.unlockAllLevels); // dev unlock auto-scrolls L1 off-screen

    testWidgets('locked node does not navigate', (tester) async {
      SharedPreferences.setMockInitialValues({}); // fresh: only L1 open
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(progressService: ProgressService()),
          onGenerateRoute: (settings) {
            if (settings.name == '/forbidden-intro') {
              navigated = true;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const Scaffold(body: Text('INTRO STUB')),
              );
            }
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Level 2 is locked on a fresh map: it renders a lock, not the number,
      // so there is no '2' node to tap. Tapping the lock icon is inert.
      final lock = find.byIcon(Icons.lock_rounded).first;
      await tester.tap(lock);
      await tester.pumpAndSettle();

      expect(navigated, isFalse);
      expect(find.text('INTRO STUB'), findsNothing);
    }, skip: DebugFlags.unlockAllLevels); // dev unlock removes all locked nodes
  });
}
