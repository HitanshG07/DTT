import 'package:flutter_test/flutter_test.dart';
import 'package:flame/extensions.dart';
import 'package:dont_tap_that/game/config/level_config.dart';
import 'package:dont_tap_that/game/config/shape_type.dart';
import 'package:dont_tap_that/game/managers/forbidden_manager.dart';

void main() {
  group('ForbiddenManager', () {
    const testConfig = LevelConfig(
      fallSpeed: 120,
      spawnRate: 0.5,
      maxObjects: 4,
      shapes: [ShapeType.circle, ShapeType.square, ShapeType.triangle],
      forbiddenChanges: false,
      forbiddenInterval: 0,
      idleDecaySeconds: 4.0,
      objectSize: 48,
    );

    test('no-repeat rule: selectForbidden excludes previous forbidden shape', () {
      const previous = ShapeType.circle;
      // Select 100 times, none should be circle
      for (int i = 0; i < 100; i++) {
        final selected = ForbiddenManager.selectForbidden(
          config: testConfig,
          previousForbidden: previous,
        );
        expect(selected, isNot(equals(previous)));
      }
    });

    test('isWithinProximity returns true if distance <= proximityRadius', () {
      final tap = Vector2(100.0, 100.0);
      final forbidden = Vector2(120.0, 120.0); // distance = sqrt(800) ~ 28.3
      expect(ForbiddenManager.isWithinProximity(tap, forbidden, proximityRadius: 80.0), isTrue);
    });

    test('isWithinProximity returns false if distance > proximityRadius', () {
      final tap = Vector2(100.0, 100.0);
      final forbidden = Vector2(200.0, 200.0); // distance = sqrt(20000) ~ 141.4
      expect(ForbiddenManager.isWithinProximity(tap, forbidden, proximityRadius: 80.0), isFalse);
    });
  });
}
