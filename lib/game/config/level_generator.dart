import 'checkpoint_spec.dart';
import 'game_constants.dart';
import 'level_config.dart';
import 'shape_type.dart';
import 'star_thresholds.dart';

/// Per-level emphasis applied on top of the base difficulty curve so levels
/// feel distinct and each *hard* level pushes ONE cognitive system, not all
/// (DTT_2.0_ROADMAP.md §7). Availability is gated by mechanic breakpoints; an
/// unavailable flavor falls back to [swarm].
enum Flavor {
  /// Breather / score-farm: longer lifetime, fewer bombs, smaller waves.
  calm,

  /// Visual search + speed: bigger waves, shorter lifetime.
  swarm,

  /// Go/no-go inhibition: more bombs, slightly slower pace.
  minefield,

  /// Working memory: more frequent checkpoints.
  recall,

  /// Set-shifting: faster forbidden rotation.
  shuffle,

  /// World boss: everything combined at a peak.
  gauntlet,
}

/// Generates the 30-level difficulty curve (2.0 Phase 4A, §7). Pure Dart.
///
/// 6 worlds × 5 levels. Difficulty follows a **sawtooth**: each world starts a
/// touch easier than the previous world's peak, then climbs past it (flow
/// channel). Continuous dials are interpolated from a normalized difficulty
/// `D ∈ [0,1]`; mechanics switch on at fixed **breakpoints**
/// (bombs @L4, checkpoints @L9, rotation @L13, order-recall @L21); a per-level
/// **flavor** nudges a few dials for variety. Finally everything is clamped to
/// **human-possible** limits.
///
/// `starOverrides` lets any level's star thresholds be hand-tuned (mandatory
/// guardrail — the generated baseline over/under-shoots realistic human scores
/// on late "Gauntlet" levels).
class LevelGenerator {
  static const int worldCount = 6;
  static const int levelsPerWorld = 5;
  static const int totalLevels = worldCount * levelsPerWorld; // 30

  // Mechanic breakpoints (1-indexed level at which each turns on).
  static const int bombsFrom = 4;
  static const int checkpointsFrom = 9;
  static const int rotationFrom = 13;
  static const int orderRecallFrom = 21;

  // Human-possible hard caps (never crossed — data-integrity / fairness).
  // Raised in Hotfix H: difficulty must come from cognitive load, not from
  // sub-human perception/motor demands. A 1.1s window on a shrinking sub-32px
  // shape among 9 objects is not "hard", it is unfair — so the floors moved up.
  static const double minLifetime = 1.7; // perceive→decide→tap floor (was 1.1)
  static const double maxBombChance = 0.30;
  static const double minRotationInterval = 12.0;
  static const int maxRecall = 4; // working-memory span ~4±1
  static const int maxConcurrentObjects = 7; // was 9 — readable screen (Hotfix H)
  static const int maxWaveSize = 6; // was 7 — no firehose waves (Hotfix H)
  static const int minObjectSize = 42; // was 32 — identifiable when shrunk (Hotfix H)

  // Frenzy-aware star tuning (Feature M). A strong player who aces a checkpoint
  // banks ~6 double-point taps during the 5 s sprint; the generated baseline
  // anticipates this so 3-star stays a fair stretch on checkpoint levels.
  static const int _frenzyTapsPerCheckpoint = 6; // midpoint of the 5–7 estimate
  static const int _frenzyExpectedCombo = 4; // representative sprint combo

  /// Shapes in introduction order (bomb excluded — it's never a normal shape).
  static const List<ShapeType> _shapeOrder = [
    ShapeType.circle,
    ShapeType.square,
    ShapeType.triangle,
    ShapeType.pentagon,
    ShapeType.star,
    ShapeType.diamond,
    ShapeType.cross,
  ];

  /// Hand-tuned star-threshold overrides, keyed by 1-indexed level.
  final Map<int, StarThresholds> starOverrides;

  const LevelGenerator({this.starOverrides = const {}});

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Normalized sawtooth difficulty for [level] (1-indexed) in [0, 1].
  static double difficultyFor(int level) {
    final int n = level.clamp(1, totalLevels);
    final int w = (n - 1) ~/ levelsPerWorld; // world index 0..5
    final int i = (n - 1) % levelsPerWorld; // level-in-world 0..4
    // Sawtooth: each world spans a 0.30-wide band that climbs 0.12 per world.
    // World 0 = [0.10, 0.40]; world 5 = [0.70, 1.00]. Each new world's floor
    // (0.22 below its own ceil) sits below the previous world's ceil → a dip.
    // Reaches exactly 1.0 only at L30, strictly increasing within every world.
    final double floor = 0.10 + w * 0.12;
    final double ceil = floor + 0.30;
    final double d = floor + (ceil - floor) * (i / (levelsPerWorld - 1));
    return d.clamp(0.0, 1.0);
  }

  /// Number of distinct shapes available at [level] (3→7, monotonic).
  static int _shapeCount(int n) {
    int c = 3;
    if (n >= 5) c++;
    if (n >= 10) c++;
    if (n >= 16) c++;
    if (n >= 22) c++;
    return c.clamp(3, 7);
  }

  /// The flavor for [level] based on its position in the world + availability.
  static Flavor flavorFor(int level) {
    final int n = level.clamp(1, totalLevels);
    final int i = (n - 1) % levelsPerWorld;
    switch (i) {
      case 0:
        return Flavor.calm;
      case 4:
        return Flavor.gauntlet;
      case 1:
        return Flavor.swarm;
      case 2:
        return n >= bombsFrom ? Flavor.minefield : Flavor.swarm;
      default: // i == 3
        if (n >= checkpointsFrom) return Flavor.recall;
        if (n >= rotationFrom) return Flavor.shuffle;
        return Flavor.swarm;
    }
  }

  /// Baseline star thresholds for [level] (overridable). Grows with the level.
  static StarThresholds _baselineStars(int n) {
    final int one = (80 + n * 40).round();
    return StarThresholds(
      one: one,
      two: (one * 2.1).round(),
      three: (one * 3.4).round(),
    );
  }

  /// Builds the [LevelConfig] for [level] (1-indexed, clamped to 1..30).
  LevelConfig forLevel(int level) {
    final int n = level.clamp(1, totalLevels);
    final double d = difficultyFor(n);
    final Flavor flavor = flavorFor(n);

    // --- base continuous dials ---
    // Hotfix H: hard-end of each lerp eased so L30 is human-clearable. The easy
    // end (L1) is unchanged, so early levels feel identical.
    double lifetime = _lerp(3.2, 1.9, d);
    double spawnRate = _lerp(0.5, 1.4, d);
    int maxObjects = _lerp(4, 7, d).round();
    int waveSize = _lerp(3, 5, d).round();
    int objectSize = _lerp(52, 42, d).round();
    double bombChance = n >= bombsFrom ? _lerp(0.05, 0.30, d) : 0.0;
    double overlap = _lerp(70, 45, d);
    double roundDuration = _lerp(55, 75, d);
    double fallSpeed = _lerp(120, 360, d); // zen only

    final bool rotating = n >= rotationFrom;
    double forbiddenInterval = rotating ? _lerp(28, 12, d) : 0.0;

    final bool cpEnabled = n >= checkpointsFrom;
    double cpInterval = _lerp(22, 12, d);
    int specials = n >= 26 ? 4 : 3;
    final bool orderMatters = n >= orderRecallFrom;
    final int distractors = n >= 16 ? 4 : 3;

    // --- flavor nudges (one system emphasized) ---
    switch (flavor) {
      case Flavor.calm:
        lifetime *= 1.25;
        bombChance *= 0.3;
        waveSize -= 1;
        break;
      case Flavor.swarm:
        waveSize += 1;
        lifetime *= 0.85;
        break;
      case Flavor.minefield:
        bombChance *= 1.4;
        spawnRate *= 0.85;
        lifetime *= 1.1;
        break;
      case Flavor.recall:
        cpInterval *= 0.7; // more frequent checkpoints
        break;
      case Flavor.shuffle:
        forbiddenInterval *= 0.7; // faster rotation
        break;
      case Flavor.gauntlet:
        lifetime *= 0.9;
        bombChance *= 1.15;
        waveSize += 1;
        spawnRate *= 1.1;
        break;
    }

    // --- human-possible hard caps (never crossed) ---
    lifetime = lifetime < minLifetime ? minLifetime : lifetime;
    bombChance = bombChance.clamp(0.0, maxBombChance);
    if (rotating) {
      forbiddenInterval =
          forbiddenInterval < minRotationInterval ? minRotationInterval : forbiddenInterval;
    }
    waveSize = waveSize.clamp(3, maxWaveSize);
    maxObjects = maxObjects.clamp(4, maxConcurrentObjects);
    if (waveSize > maxObjects) waveSize = maxObjects;
    specials = specials.clamp(1, maxRecall);
    objectSize = objectSize.clamp(minObjectSize, 52);

    final CheckpointSpec checkpoint = cpEnabled
        ? CheckpointSpec(
            enabled: true,
            interval: cpInterval,
            specialsPerWindow: specials,
            recallCount: specials,
            orderMatters: orderMatters,
            distractorCount: distractors,
          )
        : const CheckpointSpec();

    return LevelConfig(
      fallSpeed: fallSpeed,
      spawnRate: spawnRate,
      maxObjects: maxObjects,
      shapes: _shapeOrder.take(_shapeCount(n)).toList(),
      forbiddenChanges: rotating,
      forbiddenInterval: forbiddenInterval.round(),
      idleDecaySeconds: 4.0,
      spawnOverlapRadius: overlap,
      objectSize: objectSize,
      waveSize: waveSize,
      objectLifetime: lifetime,
      roundDuration: roundDuration,
      bombChance: bombChance,
      checkpoint: checkpoint,
      starThresholds: starOverrides.containsKey(n)
          ? starOverrides[n]!
          : _withFrenzyBonus(_baselineStars(n), cpEnabled, roundDuration, cpInterval),
    );
  }

  /// Lifts the 2/3-star cutoffs on checkpoint levels (Feature M) by the points a
  /// strong player banks from Frenzy sprints, so 3-star stays a fair stretch once
  /// acing checkpoints can double-score. Non-checkpoint levels are unchanged.
  /// Hand-overridden levels never reach here (the override wins outright).
  static StarThresholds _withFrenzyBonus(
    StarThresholds base,
    bool cpEnabled,
    double roundDuration,
    double cpInterval,
  ) {
    if (!cpEnabled || cpInterval <= 0) return base;
    final int expectedCheckpoints = (roundDuration / cpInterval).floor();
    if (expectedCheckpoints <= 0) return base;
    const int perCheckpoint = _frenzyTapsPerCheckpoint *
        GameConstants.kScorePerTap *
        (GameConstants.kFrenzyScoreMultiplier - 1) *
        _frenzyExpectedCombo;
    final int bonus = expectedCheckpoints * perCheckpoint;
    return StarThresholds(
      one: base.one, // 1-star stays the forgiving unlock gate
      two: base.two + bonus ~/ 2,
      three: base.three + bonus,
    );
  }
}
