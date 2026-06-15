import 'dart:math';

import 'config/level_config.dart';
import 'config/shape_type.dart';

/// Decides WHAT to spawn and WHERE. Pure Dart -- no Flame, no Flutter.
///
/// Responsibilities:
///   1. Spawn rate timer based on [LevelConfig.spawnRate]
///   2. Warmup window enforcement (FR-18)
///   3. Forbidden guarantee enforcement (FR-19)
///   4. Overlap prevention (FR-20)
///   5. Shape selection with warmup and guarantee overrides
///
/// Reference: Section 2.1, Section 2.6, FR-18, FR-19, FR-20.
class SpawnManager {
  /// Level configuration driving spawn parameters.
  final LevelConfig config;

  /// The currently forbidden shape. Updated by [DttGame] on rotation.
  ShapeType forbiddenShape;

  /// Injected random source for testability.
  final Random random;

  /// Accumulated time since last spawn decision.
  double _accumulator = 0.0;

  /// Elapsed seconds since construction (for warmup tracking).
  double _elapsed = 0.0;

  /// Seconds since the last forbidden shape was spawned (FR-19).
  double _secondsSinceLastForbidden = 0.0;

  /// Current count of active objects tracked by the caller.
  /// Updated via [updateActiveCount] before each tick.
  int _activeCount = 0;

  SpawnManager({
    required this.config,
    required this.forbiddenShape,
    required this.random,
  });

  /// Whether the game is still in the warmup window (FR-18).
  bool get isInWarmup => _elapsed < config.warmupDurationSeconds;

  /// Updates the current active object count for spawn cap checks.
  void updateActiveCount(int count) {
    _activeCount = count;
  }

  /// Advances the spawn timer by [dt] seconds and returns a
  /// [SpawnDecision] indicating whether to spawn and with what
  /// parameters.
  ///
  /// The caller should invoke this every frame with the delta time.
  SpawnDecision tick(double dt) {
    _elapsed += dt;
    _accumulator += dt;
    _secondsSinceLastForbidden += dt;

    final double spawnInterval = 1.0 / config.spawnRate;

    if (_accumulator < spawnInterval) {
      return SpawnDecision.skip();
    }

    _accumulator -= spawnInterval;

    // Warmup hard cap: max 2 concurrent objects (FR-18).
    if (isInWarmup && _activeCount >= 2) {
      return SpawnDecision.skip();
    }

    // Shape selection
    bool forceForbidden = false;

    // FR-19: guarantee forbidden appears within interval.
    if (!isInWarmup &&
        _secondsSinceLastForbidden >= config.forbiddenGuaranteeInterval) {
      forceForbidden = true;
    }

    ShapeType selectedShape;
    bool selectedIsForbidden;

    if (forceForbidden) {
      selectedShape = forbiddenShape;
      selectedIsForbidden = true;
      _secondsSinceLastForbidden = 0.0;
    } else if (isInWarmup) {
      // During warmup: never pick the forbidden shape.
      selectedShape = _pickNonForbiddenShape();
      selectedIsForbidden = false;
    } else {
      selectedShape = config.shapes[random.nextInt(config.shapes.length)];
      selectedIsForbidden = selectedShape == forbiddenShape;
      if (selectedIsForbidden) {
        _secondsSinceLastForbidden = 0.0;
      }
    }

    return SpawnDecision(
      shouldSpawn: true,
      shapeType: selectedShape,
      isForbidden: selectedIsForbidden,
      x: 0.0, // Caller uses generateX() to determine final position.
    );
  }

  /// Generates a valid x-position that does not overlap with existing
  /// objects within [config.spawnOverlapRadius] (FR-20).
  ///
  /// Tries up to 10 random positions. Falls back to a random x after
  /// 10 attempts. [gameWidth] is the available horizontal space.
  /// [existingXPositions] are the x-positions of currently active objects.
  double generateX(List<double> existingXPositions, double gameWidth) {
    final double objectSize = config.objectSize.toDouble();
    final double maxX = gameWidth - objectSize;
    if (maxX <= 0) return 0.0;

    // Cap at a maximum of 3 attempts (2 re-picks after initial attempt = 3 total attempts)
    for (int attempt = 0; attempt < 3; attempt++) {
      final double candidateX = random.nextDouble() * maxX;
      bool overlaps = false;

      for (final double existingX in existingXPositions) {
        if ((candidateX - existingX).abs() < config.spawnOverlapRadius) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        return candidateX;
      }
    }

    // Fallback after 3 attempts: screen center ± random offset (up to 20 px either way)
    // Reference: Risk 4 mitigation.
    // ignore: avoid_print
    print("WARNING: Spawn overlap check exceeded 3 attempts. Falling back to center position.");
    final double center = gameWidth / 2 - objectSize / 2;
    final double offset = (random.nextDouble() - 0.5) * 40.0;
    return (center + offset).clamp(0.0, maxX);
  }

  /// Picks a random non-forbidden shape from the level config pool.
  ShapeType _pickNonForbiddenShape() {
    final List<ShapeType> nonForbidden =
        config.shapes.where((s) => s != forbiddenShape).toList();
    if (nonForbidden.isEmpty) {
      return config.shapes[random.nextInt(config.shapes.length)];
    }
    return nonForbidden[random.nextInt(nonForbidden.length)];
  }
}

/// Result of a [SpawnManager.tick] call.
///
/// When [shouldSpawn] is true, the caller should spawn an object of
/// [shapeType] at horizontal position [x]. The [isForbidden] flag
/// indicates whether this object is the current forbidden shape.
class SpawnDecision {
  /// Whether a new object should be spawned this tick.
  final bool shouldSpawn;

  /// The shape type to spawn.
  final ShapeType shapeType;

  /// Whether the spawned object is the forbidden shape.
  final bool isForbidden;

  /// Suggested horizontal position. Caller refines via generateX().
  final double x;

  SpawnDecision({
    required this.shouldSpawn,
    required this.shapeType,
    required this.isForbidden,
    required this.x,
  });

  /// Factory for a skip (no-spawn) decision.
  factory SpawnDecision.skip() {
    return SpawnDecision(
      shouldSpawn: false,
      shapeType: ShapeType.circle,
      isForbidden: false,
      x: 0.0,
    );
  }
}