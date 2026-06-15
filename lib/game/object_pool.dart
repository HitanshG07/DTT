import 'components/falling_object.dart';

/// A fixed-size pool that recycles [FallingObject] instances.
///
/// Pre-allocates [poolSize] objects on construction. During gameplay,
/// [acquire] returns an inactive object and [release] marks it as
/// reusable. This avoids all allocations during active play (NFR-05).
///
/// The pool holds FallingObject references only. It never calls Flame
/// APIs (addChild, removeFromParent, etc). The game engine is
/// responsible for adding/removing components to the Flame tree.
///
/// Reference: Section 9, Section 7.2.
class ObjectPool {
  /// All pooled objects, pre-allocated at construction.
  final List<FallingObject> _objects;

  /// Tracks whether each slot is currently active (in use).
  final List<bool> _active;

  /// Creates a pool of [poolSize] objects using [createObject].
  ///
  /// [createObject] is called [poolSize] times during construction to
  /// pre-allocate all instances. Each call receives the slot index.
  ObjectPool({
    required int poolSize,
    required FallingObject Function(int index) createObject,
  })  : _objects = List<FallingObject>.generate(
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
  FallingObject? acquire() {
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
  void release(FallingObject obj) {
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