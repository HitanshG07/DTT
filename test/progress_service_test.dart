import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dont_tap_that/constants/debug_flags.dart';
import 'package:dont_tap_that/services/progress_service.dart';

void main() {
  group('ProgressService (2.0 Phase 4B)', () {
    late ProgressService progress;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      progress = ProgressService();
    });

    test('getStars returns 0 for a level with no record', () async {
      expect(await progress.getStars(3), 0);
    });

    test('saveStars stores stars and getStars reads them back', () async {
      await progress.saveStars(3, 2);
      expect(await progress.getStars(3), 2);
    });

    test('saveStars is best-of: a lower score never lowers stars', () async {
      await progress.saveStars(3, 3);
      await progress.saveStars(3, 1); // worse run
      expect(await progress.getStars(3), 3);
    });

    test('saveStars upgrades when beaten', () async {
      await progress.saveStars(3, 1);
      final best = await progress.saveStars(3, 2);
      expect(best, 2);
      expect(await progress.getStars(3), 2);
    });

    test('Level 1 is always unlocked', () async {
      expect(await progress.isUnlocked(1), isTrue);
    });

    test('Level N unlocks only when N-1 has >=1 star', () async {
      expect(await progress.isUnlocked(2), isFalse);
      await progress.saveStars(1, 1);
      expect(await progress.isUnlocked(2), isTrue);
    }, skip: DebugFlags.unlockAllLevels); // dev unlock opens every level

    test('getAllStars returns one entry per level in order', () async {
      await progress.saveStars(1, 3);
      await progress.saveStars(2, 1);
      final all = await progress.getAllStars(30);
      expect(all.length, 30);
      expect(all[0], 3); // level 1
      expect(all[1], 1); // level 2
      expect(all[2], 0); // level 3 (none)
    });

    test('DebugFlags.unlockAllLevels: gate short-circuits when on, gated when off',
        () async {
      // Fresh prefs: nothing earned, so Level 2/30 would normally be locked.
      if (DebugFlags.unlockAllLevels) {
        expect(await progress.isUnlocked(2), isTrue);
        expect(await progress.isUnlocked(30), isTrue);
      } else {
        // Shipped default — normal gating is enforced.
        expect(await progress.isUnlocked(2), isFalse);
        expect(await progress.isUnlocked(30), isFalse);
      }
      // getStars is never affected by the flag — star records stay honest.
      expect(await progress.getStars(2), 0);
    });
  });
}
