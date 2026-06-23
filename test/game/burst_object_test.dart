import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dont_tap_that/game/components/burst_object.dart';
import 'package:dont_tap_that/game/config/level_config.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';

/// Level-5-like config: objectSize 36 (< 48) so the hitbox floor is observable.
const _config = LevelConfig(
  fallSpeed: 320,
  spawnRate: 1.6,
  maxObjects: 8,
  shapes: [ShapeType.circle, ShapeType.square, ShapeType.triangle],
  forbiddenChanges: false,
  forbiddenInterval: 0,
  idleDecaySeconds: 4.0,
  objectSize: 36,
  waveSize: 6,
  objectLifetime: 2.0,
  roundDuration: 60.0,
);

/// Builds a [BurstObject], mounts it in a bare game, and reconfigures it with
/// [lifetime]. Returns the mounted object ready for controlled `update` calls.
Future<BurstObject> _mountedBurst(
  WidgetTester tester, {
  required double lifetime,
  void Function(BurstObject)? onExpired,
}) async {
  final game = FlameGame();
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: GameWidget(game: game))),
  );
  await tester.pump();

  final obj = BurstObject(
    shapeType: ShapeType.circle,
    isForbidden: false,
    levelConfig: _config,
    shapeColor: const Color(0xFFF2F2F2),
    onCorrectTap: (_) {},
    onWrongTap: (_) {},
    onBombTap: (_) {},
    onExpired: onExpired ?? (_) {},
  );
  await game.add(obj);
  // Mount the object + its onLoad hitbox child.
  await tester.pump();
  await tester.pump();

  obj.reconfigure(
    newShapeType: ShapeType.circle,
    newIsForbidden: false,
    newPosition: Vector2(20, 120),
    newLifetime: lifetime,
  );
  return obj;
}

void main() {
  group('BurstObject', () {
    testWidgets('lifeFraction tracks remaining/lifetime as it drains', (tester) async {
      final obj = await _mountedBurst(tester, lifetime: 2.0);
      expect(obj.lifeFraction, closeTo(1.0, 1e-6));

      obj.update(1.0); // half the lifetime
      expect(obj.lifeFraction, closeTo(0.5, 1e-3));

      obj.update(0.5); // three-quarters elapsed
      expect(obj.lifeFraction, closeTo(0.25, 1e-3));
    });

    testWidgets('visualScale floors at 0.5 — shapes stay readable to expiry (Hotfix H)',
        (tester) async {
      final obj = await _mountedBurst(tester, lifetime: 2.0);
      // Full life → full size.
      expect(obj.visualScale, closeTo(1.0, 1e-6));

      // Half life → halfway between the 0.5 floor and 1.0 = 0.75.
      obj.update(1.0);
      expect(obj.visualScale, closeTo(0.75, 1e-3));

      // Drained to (near) zero life → clamps at the 0.5 floor, never smaller.
      obj.update(1.9);
      expect(obj.lifeFraction, lessThan(0.05));
      expect(obj.visualScale, greaterThanOrEqualTo(BurstObject.kMinVisualScale));
      expect(obj.visualScale, closeTo(0.5, 1e-2));
    });

    testWidgets(
      'onTapDown consumes the tap (stops propagation) so it cannot hit two '
      'overlapping objects at once',
      (tester) async {
        final game = FlameGame();
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: GameWidget(game: game))),
        );
        await tester.pump();

        int correctTaps = 0;
        final obj = BurstObject(
          shapeType: ShapeType.circle,
          isForbidden: false,
          levelConfig: _config,
          shapeColor: const Color(0xFFF2F2F2),
          onCorrectTap: (_) => correctTaps++,
          onWrongTap: (_) {},
          onBombTap: (_) {},
          onExpired: (_) {},
        );
        await game.add(obj);
        await tester.pump();
        await tester.pump();

        // Flame's multi-tap dispatcher delivers tap-downs to ALL components at
        // the point (deliverToAll: true), so it sets continuePropagation=true
        // before each handler. Simulate that, then confirm the handler turns it
        // back off — i.e. an object beneath would NOT also receive this tap.
        final event = TapDownEvent(
          0,
          game,
          TapDownDetails(globalPosition: const Offset(20, 120)),
        );
        event.continuePropagation = true;
        obj.onTapDown(event);

        expect(event.continuePropagation, isFalse);
        expect(correctTaps, 1);
      },
    );

    testWidgets('fires onExpired exactly once when lifetime runs out', (tester) async {
      int expiredCount = 0;
      final obj = await _mountedBurst(
        tester,
        lifetime: 1.0,
        onExpired: (_) => expiredCount++,
      );

      obj.update(1.0); // remaining -> 0: expire
      expect(expiredCount, 1);

      obj.update(1.0); // already handled: must not fire again
      expect(expiredCount, 1);
    });

    testWidgets('hitbox stays at the 48px floor even though the visual shrinks', (tester) async {
      final obj = await _mountedBurst(tester, lifetime: 2.0);

      // objectSize is 36, so the hitbox is clamped up to the 48px floor (NFR-07).
      final hitbox = obj.children.whereType<RectangleHitbox>().first;
      expect(hitbox.size.x, greaterThanOrEqualTo(48.0));
      expect(hitbox.size.x, equals(48.0));

      final double sizeBefore = hitbox.size.x;

      // Drain most of the lifetime: the visual shrinks (lifeFraction drops)...
      obj.update(1.8);
      expect(obj.lifeFraction, lessThan(0.2));
      // ...but the hitbox does not.
      expect(hitbox.size.x, equals(sizeBefore));
    });
  });
}
