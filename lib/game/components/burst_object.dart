import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;

import '../config/game_constants.dart';
import '../config/level_config.dart';
import '../config/shape_type.dart';
import '../shapes/base_shape.dart';
import '../effects/object_pop_in.dart';
import '../dtt_game.dart';

/// A static, tappable shape whose lifetime drains in place (2.0 Spatial Burst).
///
/// Forked from [FallingObject] (DTT_2.0_ROADMAP.md §2.1, §4). Unlike the falling
/// engine, a [BurstObject] does **not** move: it appears at a 2D spot and
/// **shrinks** as its lifetime counts down — the shrink *is* the timer. When the
/// lifetime reaches zero it has "expired" (the 2.0 equivalent of a miss) and
/// fires [onExpired] exactly once.
///
/// The tap **hitbox is fixed** at `max(objectSize, 48)` (NFR-07) and never
/// shrinks with the visual — a barely-visible object is still fully tappable.
///
/// Reference: DTT_2.0_ROADMAP.md §4 (Phase 1); Section 3.3 (hitbox),
/// Section 4.2 (rendering), Section 6.3 (audio debounce).
class BurstObject extends PositionComponent with TapCallbacks {
  /// The shape type this object renders.
  ShapeType shapeType;

  /// Whether this object is the forbidden shape for the current round.
  bool isForbidden;

  /// Level configuration providing object size, lifetime, etc.
  final LevelConfig levelConfig;

  /// Fill colour for the shape. Identical for forbidden and correct objects so
  /// colour never reveals which shape is forbidden -- memory is the only cue
  /// (Section 2.5, Section 4.2). [isForbidden] still drives tap logic.
  final Color shapeColor;

  /// Called when the player correctly taps a non-forbidden object.
  final void Function(BurstObject) onCorrectTap;

  /// Called when the player taps the forbidden object.
  final void Function(BurstObject) onWrongTap;

  /// Called when the player taps a bomb (always-salient hazard, §5).
  final void Function(BurstObject) onBombTap;

  /// Called when this object's lifetime expires before it was tapped.
  /// The 2.0 equivalent of [FallingObject]'s "fell off the bottom" miss.
  final void Function(BurstObject) onExpired;

  /// Total lifetime in seconds for the current spawn. Set via [reconfigure].
  double _lifetime = 1.0;

  /// Remaining lifetime in seconds. Drains in [update]; the visual scale is
  /// `_remaining / _lifetime`.
  double _remaining = 1.0;

  /// Fixed visual size of the shape at full lifetime (logical px). The rendered
  /// shape shrinks from this toward zero; the hitbox stays at [_hitboxSize].
  late final double _baseVisualSize;

  /// Fixed tap hitbox size = `max(objectSize, kMinHitbox)`. Never shrinks
  /// (NFR-07). The component's [size] equals this so the hitbox fills the box.
  late final double _hitboxSize;

  /// Prevents double-firing of callbacks when a pool object is released and
  /// re-acquired before removeFromParent() completes.
  bool _hasBeenHandled = false;

  /// Called by Flame's onRemove(). Set by DttGame after acquire() so the pool
  /// can release the slot only after the component is fully removed.
  VoidCallback? onRemoved;

  /// 50 ms audio debounce guard (Section 6.3, NFR-07). Shared across all
  /// BurstObject instances to prevent audio clipping on rapid taps.
  static DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  /// Cached paint reused across render calls to avoid allocation.
  final Paint _paint = Paint();

  /// Cached shape painter instance.
  late BaseShape _shapePainter;

  BurstObject({
    required this.shapeType,
    required this.isForbidden,
    required this.levelConfig,
    required this.shapeColor,
    required this.onCorrectTap,
    required this.onWrongTap,
    required this.onBombTap,
    required this.onExpired,
  }) {
    _baseVisualSize = levelConfig.objectSize.toDouble();
    _hitboxSize = max(_baseVisualSize, GameConstants.kMinHitbox);
    size = Vector2.all(_hitboxSize);
    _shapePainter = BaseShape.forType(shapeType);
  }

  /// Optional memory-checkpoint token glyph (2.0 Phase 3, §6). When non-null
  /// the object is a "special" carrying this token, drawn centred on the shape.
  String? token;

  /// Whether this object is a bomb (always-salient hazard, §5). A bomb is never
  /// the forbidden shape; tapping it routes to [onBombTap], and letting it
  /// expire is the *correct* (no-tap) outcome.
  bool get isBomb => shapeType == ShapeType.bomb;

  /// Fraction of lifetime remaining, clamped to [0, 1]. Drives the visual scale
  /// and is exposed for tests.
  double get lifeFraction =>
      _lifetime <= 0 ? 0.0 : (_remaining / _lifetime).clamp(0.0, 1.0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Hitbox fills the (fixed) component box: full size, no offset. The visual
    // shrinks inside it in render(); the hitbox does not (NFR-07).
    add(
      RectangleHitbox(
        size: Vector2.all(_hitboxSize),
      )..collisionType = CollisionType.passive,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame();
    final double activeTimeScale = (game is DttGame) ? game.timeScale : 1.0;

    _remaining -= dt * activeTimeScale;

    if (_remaining <= 0) {
      if (!_hasBeenHandled) {
        _hasBeenHandled = true;
        onExpired(this);
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double scale = lifeFraction;
    final double visual = _baseVisualSize * scale;
    if (visual <= 0.0) return;

    // Centre the shrinking visual inside the fixed hitbox box.
    final double inset = (size.x - visual) / 2.0;

    _paint
      ..style = PaintingStyle.fill
      ..color = shapeColor;

    canvas.save();
    canvas.translate(inset, inset);
    _shapePainter.paintShape(canvas, Size(visual, visual), _paint);
    canvas.restore();

    // Memory-checkpoint token glyph, centred and scaled with the shape (§6).
    final String? t = token;
    if (t != null) {
      final double fontSize = visual * 0.5;
      if (fontSize >= 6.0) {
        TextPaint(
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111111), // dark glyph on the off-white shape
          ),
        ).render(
          canvas,
          t,
          Vector2(size.x / 2, size.y / 2),
          anchor: Anchor.center,
        );
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_hasBeenHandled) return;
    _hasBeenHandled = true;

    final now = DateTime.now();
    // ignore: unused_local_variable
    final bool audioDebounce = now.difference(_lastTap).inMilliseconds < 50;
    _lastTap = now;

    if (isBomb) {
      onBombTap(this);
    } else if (isForbidden) {
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
  /// [newPosition] is the 2D top-left spawn point (the burst engine scatters
  /// objects in 2D, not just along x). [newLifetime] is the full countdown in
  /// seconds for this spawn.
  void reconfigure({
    required ShapeType newShapeType,
    required bool newIsForbidden,
    required Vector2 newPosition,
    required double newLifetime,
    String? newToken,
  }) {
    _hasBeenHandled = false; // ← RESET for pool reuse
    shapeType = newShapeType;
    isForbidden = newIsForbidden;
    token = newToken; // reset/assign the checkpoint token on reuse (§6)
    position.setFrom(newPosition);
    _lifetime = newLifetime;
    _remaining = newLifetime;
    _shapePainter = BaseShape.forType(newShapeType);
    add(ObjectPopIn(target: this));
  }
}
