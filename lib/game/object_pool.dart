import 'package:flame/components.dart';

/// A fixed-size pool that recycles [PositionComponent] instances.
///
/// Generic over the pooled component type [T] so the same pool serves the
/// 2.0 [BurstObject] (Phases 1–4) and the preserved [FallingObject] (Phase 5
/// "Zen") without either component being modified (DTT_2.0_ROADMAP.md §2.1).
///
/// Pre-allocates [poolSize] objects on construction. During gameplay,
/// [acquire] returns an inactive object and [release] marks it as
/// reusable. This avoids all allocations during active play (NFR-05).
///
/// The pool holds component references only. It never calls Flame
/// APIs (addChild, removeFromParent, etc). The game engine is
/// responsible for adding/removing components to the Flame tree.
///
/// Reference: Section 9, Section 7.2.
class ObjectPool<T extends PositionComponent> {
  /// All pooled objects, pre-allocated at construction.
  final List<T> _objects;

  /// Tracks whether each slot is currently active (in use).
  final List<bool> _active;

  /// Creates a pool of [poolSize] objects using [createObject].
  ///
  /// [createObject] is called [poolSize] times during construction to
  /// pre-allocate all instances. Each call receives the slot index.
  ObjectPool({
    required int poolSize,
    required T Function(int index) createObject,
  })  : _objects = List<T>.generate(
          poolSize,
          (i) => createObject(i),
        ),
        _active = List<bool>.filled(poolSize, false);

  /// Returns the total pool capacity.
  int get poolSize => _objects.length;

  /// Returns the count of currently active (in-use) objects.
  int get activeCount => _active.where((a) => a).length;

  /// Returns an inactive object from the pool, or null if all
  /// objects are active (pool exhausted). Spawn is skipped silently
  /// when the pool is exhausted.
  T? acquire() {
    for (int i = 0; i < _objects.length; i++) {
      if (!_active[i]) {
        _active[i] = true;
        return _objects[i];
      }
    }
    return null;
  }

  /// Marks [obj] as inactive and resets its position to off-screen
  /// top (y = -objectSize). The game engine must call
  /// removeFromParent() separately before releasing.
  void release(T obj) {
    for (int i = 0; i < _objects.length; i++) {
      if (identical(_objects[i], obj)) {
        _active[i] = false;
        obj.position.y = -obj.size.x;
        return;
      }
    }
  }

  /// Returns a list of x-positions of all currently active objects.
  /// Used by [SpawnManager] for overlap prevention (FR-20).
  List<double> get activeXPositions {
    final List<double> positions = <double>[];
    for (int i = 0; i < _objects.length; i++) {
      if (_active[i]) {
        positions.add(_objects[i].position.x);
      }
    }
    return positions;
  }
}