import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';

import '../config/game_constants.dart';
import '../config/level_config.dart';
import '../config/shape_type.dart';
import '../shapes/base_shape.dart';
import '../effects/object_pop_in.dart';
import '../dtt_game.dart';

/// A falling shape component that the player can tap.
///
/// Renders using [BaseShape.forType] and delegates tap results to
/// callbacks provided by the game engine. Visual size is
/// [levelConfig.objectSize], but the tap hitbox is always at least
/// [GameConstants.kMinHitbox] (48 px) per NFR-07.
///
/// Reference: Section 2.1 (spawning / falling), Section 3.3 (hitbox),
/// Section 4.2 (rendering), Section 2.5 (slow-motion), Section 6.3
/// (audio debounce).
class FallingObject extends PositionComponent with TapCallbacks {
  /// The shape type this object renders.
  ShapeType shapeType;

  /// Whether this object is the forbidden shape for the current round.
  bool isForbidden;

  /// Level configuration providing fall speed, object size, etc.
  final LevelConfig levelConfig;

  /// Colour used when this object is a correct (non-forbidden) shape.
  final Color correctColor;

  /// Colour used when this object is the forbidden shape.
  final Color forbiddenColor;

  /// Called when the player correctly taps a non-forbidden object.
  final void Function(FallingObject) onCorrectTap;

  /// Called when the player taps the forbidden object.
  final void Function(FallingObject) onWrongTap;

  /// Called when this object falls off the bottom of the screen.
  final void Function(FallingObject) onMissed;

  /// Multiplier applied to fall speed for slow-motion support.
  /// Default 1.0. Set by DttGame when slow-motion activates.
  /// Reference: Section 2.5, kSlowMotionScale.
  double speedMultiplier = 1.0;

  /// Prevents double-firing of callbacks when a pool object is
  /// released and re-acquired before removeFromParent() completes.
  bool _hasBeenHandled = false;

  /// Called by Flame's onRemove(). Set by DttGame after acquire()
  /// so the pool can release the slot only after the component is
  /// fully removed from the tree.
  VoidCallback? onRemoved;

  /// 50 ms audio debounce guard (Section 6.3, NFR-07).
  /// Shared across all FallingObject instances to prevent audio
  /// clipping when multiple taps fire within the debounce window.
  static DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  /// Cached paint object reused across render calls to avoid allocation.
  final Paint _paint = Paint();

  /// Cached shape painter instance.
  late BaseShape _shapePainter;

  FallingObject({
    required this.shapeType,
    required this.isForbidden,
    required this.levelConfig,
    required this.correctColor,
    required this.forbiddenColor,
    required this.onCorrectTap,
    required this.onWrongTap,
    required this.onMissed,
  }) : super(
          size: Vector2.all(levelConfig.objectSize.toDouble()),
        ) {
    _shapePainter = BaseShape.forType(shapeType);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final double visualSize = levelConfig.objectSize.toDouble();
    final double hitboxSize =
        visualSize > GameConstants.kMinHitbox
            ? visualSize
            : GameConstants.kMinHitbox;

    final double offset = (hitboxSize - visualSize) / 2.0;

    add(
      RectangleHitbox(
        size: Vector2.all(hitboxSize),
        position: Vector2.all(-offset),
      )..collisionType = CollisionType.passive,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame();
    final double activeTimeScale = (game is DttGame) ? game.timeScale : 1.0;
    position.y += levelConfig.fallSpeed * speedMultiplier * activeTimeScale * dt;

    if (findGame() != null && position.y > findGame()!.size.y + size.x) {
      if (!_hasBeenHandled) {
        _hasBeenHandled = true;
        onMissed(this);
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    _paint
      ..style = PaintingStyle.fill
      ..color = isForbidden ? forbiddenColor : correctColor;

    _shapePainter.paintShape(
      canvas,
      Size(size.x, size.y),
      _paint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_hasBeenHandled) return;
    _hasBeenHandled = true;

    final now = DateTime.now();
    // ignore: unused_local_variable
    final bool audioDebounce =
        now.difference(_lastTap).inMilliseconds < 50;
    _lastTap = now;

    if (isForbidden) {
      onWrongTap(this);
    } else {
      onCorrectTap(this);
    }

    removeFromParent();
  }

  @override
  void onRemove() {
    super.onRemove();
    onRemoved?.call();
  }

  /// Reconfigures this object for reuse from the pool.
  ///
  /// Called by [ObjectPool] or [DttGame] when recycling a pooled instance.
  void reconfigure({
    required ShapeType newShapeType,
    required bool newIsForbidden,
    required Vector2 newPosition,
    required double newSpeedMultiplier,
  }) {
    _hasBeenHandled = false;   // ← RESET for pool reuse
    shapeType = newShapeType;
    isForbidden = newIsForbidden;
    position.setFrom(newPosition);
    speedMultiplier = newSpeedMultiplier;
    _shapePainter = BaseShape.forType(newShapeType);
    add(ObjectPopIn(target: this));
  }
}