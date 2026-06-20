import 'shape_type.dart';

/// A single scripted spawn instruction for the tutorial (Stage 7).
///
/// Pure Dart -- no Flame, no Flutter. Consumed by [SpawnManager] when an
/// optional [SpawnScript] is supplied; ignored entirely during normal random
/// play (script == null). Reference: Section 12.3 (tutorial hook table).
class SpawnScriptEntry {
  /// Seconds to wait, since the previous scripted spawn, before this one fires.
  final double delay;

  /// The shape to spawn.
  final ShapeType shapeType;

  /// Explicit horizontal position. When null the caller falls back to
  /// [SpawnManager.generateX] to choose a non-overlapping position.
  final double? x;

  const SpawnScriptEntry({
    required this.delay,
    required this.shapeType,
    this.x,
  });
}

/// An ordered list of scripted spawns driving the interactive tutorial.
///
/// Passed to [SpawnManager] via its optional `script` parameter. The manager
/// emits one [SpawnScriptEntry] at a time in order, then idles once the list
/// is exhausted. Reference: Section 10.1 (rework-trap table), Section 12.3.
class SpawnScript {
  final List<SpawnScriptEntry> entries;

  const SpawnScript(this.entries);
}
