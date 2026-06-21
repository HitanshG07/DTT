import 'dart:math';

import 'config/level_config.dart';
import 'config/shape_type.dart';
import 'config/spawn_script.dart';

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

  /// Optional scripted spawn sequence for the interactive tutorial (Stage 7).
  ///
  /// Default null = ordinary random spawning. When supplied, the script fully
  /// drives spawn decisions and the random/warmup/guarantee logic is bypassed.
  /// Reference: Section 10.1 (rework-trap table), Section 12.3.
  final SpawnScript? script;

  /// Index of the next [SpawnScriptEntry] to emit (scripted mode only).
  int _scriptIndex = 0;

  /// Time accumulated toward the current scripted entry's delay.
  double _scriptTimer = 0.0;

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
    this.script,
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

    // Scripted (tutorial) mode fully overrides random/warmup/guarantee logic.
    if (script != null) {
      return _tickScripted(dt);
    }

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

  /// Advances the spawn timer by [dt] and returns a **wave** of decisions for
  /// 2.0 Burst mode (DTT_2.0_ROADMAP.md §4, Phase 1).
  ///
  /// Returns an empty list when no spawn is due this tick. When due, returns
  /// [config.waveSize] decisions (one full wave). The caller assigns each a 2D
  /// position via [generate2DPosition] and caps the total against the pool /
  /// [config.maxObjects].
  ///
  /// Preserves the 1.x invariants: warmup behaves like the single-spawn path
  /// (max 2 concurrent, never forbidden, FR-18); the forbidden-guarantee
  /// (FR-19) forces exactly one forbidden into the wave when overdue; and
  /// **`isForbidden` is true iff `shapeType == forbiddenShape`** for every
  /// decision (FR-13).
  List<SpawnDecision> tickWave(double dt) {
    _elapsed += dt;
    _accumulator += dt;
    _secondsSinceLastForbidden += dt;

    // Scripted (tutorial) mode emits single-item waves.
    if (script != null) {
      final d = _tickScripted(dt);
      return d.shouldSpawn ? <SpawnDecision>[d] : const <SpawnDecision>[];
    }

    final double spawnInterval = 1.0 / config.spawnRate;
    if (_accumulator < spawnInterval) {
      return const <SpawnDecision>[];
    }
    _accumulator -= spawnInterval;

    // Warmup: single non-forbidden object, max 2 concurrent (FR-18).
    if (isInWarmup) {
      if (_activeCount >= 2) return const <SpawnDecision>[];
      return <SpawnDecision>[
        SpawnDecision(
          shouldSpawn: true,
          shapeType: _pickNonForbiddenShape(),
          isForbidden: false,
          x: 0.0,
        ),
      ];
    }

    // Full wave.
    final decisions = <SpawnDecision>[];
    bool needForbidden =
        _secondsSinceLastForbidden >= config.forbiddenGuaranteeInterval;

    for (int i = 0; i < config.waveSize; i++) {
      ShapeType shape;
      bool isForbidden;
      if (needForbidden) {
        // FR-19: force exactly one guaranteed forbidden per overdue wave.
        shape = forbiddenShape;
        isForbidden = true;
        needForbidden = false;
        _secondsSinceLastForbidden = 0.0;
      } else if (config.bombChance > 0 &&
          random.nextDouble() < config.bombChance) {
        // Bomb hazard (§5): always-salient, never the forbidden shape. The
        // `> 0` guard means bomb-free configs consume no randomness here, so
        // the falling/Phase-1 wave behaviour is unchanged.
        shape = ShapeType.bomb;
        isForbidden = false;
      } else {
        shape = config.shapes[random.nextInt(config.shapes.length)];
        isForbidden = shape == forbiddenShape;
        if (isForbidden) _secondsSinceLastForbidden = 0.0;
      }
      decisions.add(SpawnDecision(
        shouldSpawn: true,
        shapeType: shape,
        isForbidden: isForbidden,
        x: 0.0,
      ));
    }
    return decisions;
  }

  /// Generates a valid 2D spawn point that does not overlap existing objects
  /// within [config.spawnOverlapRadius] (FR-20, 2D variant of [generateX]).
  ///
  /// [existingX]/[existingY] are parallel lists of active object positions.
  /// The point is placed inside the play rect `[0,areaWidth) x [areaTop,
  /// areaTop+areaHeight)`. Tries up to 3 positions, then falls back to the play
  /// area centre with a small jitter. Returns `(x, y)`. Pure Dart -- no Flame.
  (double, double) generate2DPosition(
    List<double> existingX,
    List<double> existingY,
    double areaWidth,
    double areaHeight, {
    double areaTop = 0.0,
  }) {
    final double objectSize = config.objectSize.toDouble();
    final double maxX = areaWidth - objectSize;
    final double maxY = areaHeight - objectSize;
    if (maxX <= 0 || maxY <= 0) {
      return (0.0, areaTop);
    }

    for (int attempt = 0; attempt < 3; attempt++) {
      final double cx = random.nextDouble() * maxX;
      final double cy = areaTop + random.nextDouble() * maxY;
      bool overlaps = false;
      for (int j = 0; j < existingX.length; j++) {
        final double dx = cx - existingX[j];
        final double dy = cy - existingY[j];
        if (sqrt(dx * dx + dy * dy) < config.spawnOverlapRadius) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) return (cx, cy);
    }

    // Fallback after 3 attempts: play-area centre ± small jitter (Risk-4).
    assert(() {
      // ignore: avoid_print
      print("WARNING: 2D spawn overlap check exceeded 3 attempts. Falling back to centre.");
      return true;
    }());
    final double cx =
        (maxX / 2 + (random.nextDouble() - 0.5) * 40.0).clamp(0.0, maxX);
    final double cy =
        (areaTop + maxY / 2 + (random.nextDouble() - 0.5) * 40.0)
            .clamp(areaTop, areaTop + maxY);
    return (cx, cy);
  }

  /// Drives spawn decisions from the optional [script] (tutorial Stage 7).
  ///
  /// Emits one [SpawnScriptEntry] at a time, in order, once its [delay] has
  /// elapsed since the previous scripted spawn. Returns [SpawnDecision.skip]
  /// while waiting and once the script is exhausted. An entry's explicit
  /// [SpawnScriptEntry.x] is carried through on the decision; when null the
  /// caller falls back to [generateX]. Reference: Section 12.3.
  SpawnDecision _tickScripted(double dt) {
    final entries = script!.entries;
    if (_scriptIndex >= entries.length) {
      return SpawnDecision.skip();
    }

    _scriptTimer += dt;
    final entry = entries[_scriptIndex];
    if (_scriptTimer < entry.delay) {
      return SpawnDecision.skip();
    }

    _scriptTimer = 0.0;
    _scriptIndex++;

    final bool isForbidden = entry.shapeType == forbiddenShape;
    if (isForbidden) {
      _secondsSinceLastForbidden = 0.0;
    }

    return SpawnDecision(
      shouldSpawn: true,
      shapeType: entry.shapeType,
      isForbidden: isForbidden,
      x: entry.x ?? 0.0,
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
    // Reference: Risk 4 mitigation. Debug-only log to avoid spamming release output.
    assert(() {
      // ignore: avoid_print
      print("WARNING: Spawn overlap check exceeded 3 attempts. Falling back to center position.");
      return true;
    }());
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