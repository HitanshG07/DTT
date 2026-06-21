import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/effects/white_blast_effect.dart';

void main() {
  group('WhiteBlastEffect (§5 seizure safety)', () {
    test('opacity is hard-capped at 0.75 (and reduced even lower)', () {
      // Guards the seizure-safety contract: the blast must never strobe to full
      // white. The cap is a const so it can't silently drift.
      expect(WhiteBlastEffect.kMaxOpacity, 0.75);
      expect(WhiteBlastEffect.kMaxOpacity, lessThanOrEqualTo(0.75));
      expect(WhiteBlastEffect.kReducedMaxOpacity, lessThan(WhiteBlastEffect.kMaxOpacity));
    });

    test('stores the reduced (Reduce-flashing) flag', () {
      expect(WhiteBlastEffect(reduced: true).reduced, isTrue);
      expect(WhiteBlastEffect().reduced, isFalse);
    });

    testWidgets('is a single pulse that auto-removes after its duration', (tester) async {
      final game = FlameGame();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GameWidget(game: game))),
      );
      await tester.pump();

      final blast = WhiteBlastEffect();
      await game.add(blast);
      await tester.pump();
      expect(blast.isMounted, isTrue);

      // Past the 150 ms pulse -> the component removes itself (no strobe/repeat).
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(game.children.whereType<WhiteBlastEffect>().isEmpty, isTrue);
    });
  });
}
