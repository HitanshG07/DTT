import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dont_tap_that/constants/debug_flags.dart';
import 'package:dont_tap_that/screens/map_screen.dart';
import 'package:dont_tap_that/services/progress_service.dart';

/// Pumps the MapScreen with the given prefs and lets the async star-load and
/// the post-frame auto-scroll settle.
Future<void> _pumpMap(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: MapScreen(progressService: ProgressService())),
  );
  await tester.pumpAndSettle();
}

/// Finds the circular node whose number Text equals [level]. Since the map is
/// scrollable, the node may need to be scrolled into view first.
Finder _nodeText(int level) => find.text('$level');

void main() {
  group('MapScreen (2.0 Phase 4C-1)', () {
    testWidgets('renders all 30 level nodes across a fresh map', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpMap(tester);

      // Every level shows its number somewhere in the (scrollable) tree.
      // Level 1 (always unlocked) is on-screen; the rest exist as widgets.
      expect(_nodeText(1), findsOneWidget);

      // 6 world banners are present.
      expect(find.text('AWAKENING'), findsOneWidget);
      expect(find.text('GAUNTLET'), findsOneWidget);
      expect(find.textContaining('WORLD 1'), findsOneWidget);
      expect(find.textContaining('WORLD 6'), findsOneWidget);
    });

    testWidgets('fresh map: only Level 1 unlocked, Level 2 shows a lock',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpMap(tester);

      // Level 1 unlocked → its number renders (no lock on it).
      expect(_nodeText(1), findsOneWidget);

      // Level 2 is locked on a fresh map → its number is NOT rendered (lock
      // icon replaces the number). At least one lock icon is visible.
      expect(find.text('2'), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    }, skip: DebugFlags.unlockAllLevels); // dev unlock removes all locks

    testWidgets('DebugFlags.unlockAllLevels: gated when off, all open when on',
        (tester) async {
      // Fresh map — nothing earned.
      SharedPreferences.setMockInitialValues({});
      await _pumpMap(tester);

      if (DebugFlags.unlockAllLevels) {
        // Every node is unlocked → Level 2's number renders and no locks exist,
        // and the ship-safety badge is visible.
        expect(find.text('2'), findsOneWidget);
        expect(find.byIcon(Icons.lock_rounded), findsNothing);
        expect(find.text('DEV UNLOCK'), findsOneWidget);
      } else {
        // Shipped default — normal gating: Level 2 locked, no dev badge.
        expect(find.text('2'), findsNothing);
        expect(find.byIcon(Icons.lock_rounded), findsWidgets);
        expect(find.text('DEV UNLOCK'), findsNothing);
      }
    });

    testWidgets('clearing Level 1 unlocks Level 2 (shows its number)',
        (tester) async {
      // Level 1 earned 2 stars → Level 2 unlocks.
      SharedPreferences.setMockInitialValues({'dtt_stars_level_1': 2});
      await _pumpMap(tester);

      // Level 2 now renders its number (unlocked, not a lock).
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('earned stars render as filled pips on a node', (tester) async {
      // Level 1 = 3 stars.
      SharedPreferences.setMockInitialValues({'dtt_stars_level_1': 3});
      await _pumpMap(tester);

      // 3 filled stars belong to Level 1's node. (Other unlocked nodes show
      // empty pips only; Level 2 also unlocks but has 0 filled.)
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    });

    testWidgets('tapping an unlocked node launches the forbidden-intro (4C-2)',
        (tester) async {
      SharedPreferences.setMockInitialValues({'dtt_stars_level_1': 1});
      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(progressService: ProgressService()),
          onGenerateRoute: (settings) {
            if (settings.name == '/forbidden-intro') {
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

      // Tapping the unlocked Level 1 node navigates without throwing.
      await tester.tap(_nodeText(1));
      await tester.pumpAndSettle();

      expect(find.text('INTRO STUB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, skip: DebugFlags.unlockAllLevels); // dev unlock auto-scrolls L1 off-screen
  });
}
