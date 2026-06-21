import 'checkpoint_spec.dart';
import 'shape_type.dart';
import 'star_thresholds.dart';

/// Configuration for a single difficulty level.
///
/// All fields from Section 3.2 of the planning document. Immutable.
/// [objectSize] controls visual rendering only -- tap hitbox is always
/// max(objectSize, 48) as defined in Section 3.3.
///
/// Reference: Section 3.2 -- LevelConfig Class (Dart).
class LevelConfig {
  /// Fall speed in logical pixels per second.
  final double fallSpeed;

  /// Objects spawned per second.
  final double spawnRate;

  /// Maximum concurrent objects on screen, bounded by pool size.
  final int maxObjects;

  /// Shape types available at this level.
  final List<ShapeType> shapes;

  /// Whether the forbidden shape changes mid-round.
  final bool forbiddenChanges;

  /// Seconds between forbidden shape changes (only relevant when
  /// [forbiddenChanges] is true).
  final int forbiddenInterval;

  /// Seconds of no tapping before combo multiplier drops by 1 step.
  /// Reference: Section 2.3 -- idle decay.
  final double idleDecaySeconds;

  /// Duration of the warmup window in seconds.
  /// During warmup: max 2 objects, no forbidden spawns.
  /// Reference: Section 2.6 / FR-18.
  final int warmupDurationSeconds;

  /// Forbidden shape must appear at least once within this interval
  /// in seconds. If not spawned naturally, the next spawn is forced.
  /// Reference: FR-19.
  final int forbiddenGuaranteeInterval;

  /// Minimum distance in logical pixels between newly spawned objects
  /// and existing active objects. Reference: FR-20.
  final double spawnOverlapRadius;

  /// Visual size of objects in logical pixels. Shrinks across levels
  /// (48 at Level 1 to 36 at Level 5). Tap hitbox is always >= 48 px.
  /// Reference: Section 3.1 parameter table, Section 4.2.
  final int objectSize;

  // --- 2.0 Spatial Burst fields (DTT_2.0_ROADMAP.md §4, Phase 1) ---
  // Defaulted so existing 1.x const configs and tests compile unchanged; the
  // burst engine reads these, the falling/Zen engine ignores them.

  /// Number of objects emitted per spawn wave in Burst mode (typically 4–6).
  /// Bounded by [maxObjects] and the pool size at spawn time.
  final int waveSize;

  /// Lifetime in seconds of a Burst object before it expires (shrinks to
  /// nothing). Shorter = harder. Reference: §4 (Phase 1).
  final double objectLifetime;

  /// Total round countdown in seconds for Burst mode. The round ends when this
  /// reaches 0 (or, in Phase 1, when lives reach 0). Reference: §4 (Phase 1).
  final double roundDuration;

  /// Probability [0,1] that a non-guaranteed wave slot spawns a bomb instead of
  /// a normal shape (2.0 Burst, §5). Bombs are never the forbidden shape.
  /// Default 0.0 (no bombs) so 1.x configs/tests are unaffected.
  final double bombChance;

  /// Working-memory checkpoint configuration (2.0 Phase 3, §6). Disabled by
  /// default so earlier levels / 1.x configs have no checkpoints.
  final CheckpointSpec checkpoint;

  /// Score cutoffs for the 3-star mastery tiers (2.0 Phase 4, §7).
  final StarThresholds starThresholds;

  const LevelConfig({
    required this.fallSpeed,
    required this.spawnRate,
    required this.maxObjects,
    required this.shapes,
    required this.forbiddenChanges,
    required this.forbiddenInterval,
    required this.idleDecaySeconds,
    this.warmupDurationSeconds = 12,
    this.forbiddenGuaranteeInterval = 8,
    this.spawnOverlapRadius = 60,
    required this.objectSize,
    this.waveSize = 5,
    this.objectLifetime = 2.5,
    this.roundDuration = 60.0,
    this.bombChance = 0.0,
    this.checkpoint = const CheckpointSpec(),
    this.starThresholds =
        const StarThresholds(one: 100, two: 200, three: 300),
  });

  /// Returns a copy with the given fields replaced. Useful for tuning variants
  /// and for tests that need one field changed (e.g. disabling checkpoints).
  LevelConfig copyWith({
    double? fallSpeed,
    double? spawnRate,
    int? maxObjects,
    List<ShapeType>? shapes,
    bool? forbiddenChanges,
    int? forbiddenInterval,
    double? idleDecaySeconds,
    int? warmupDurationSeconds,
    int? forbiddenGuaranteeInterval,
    double? spawnOverlapRadius,
    int? objectSize,
    int? waveSize,
    double? objectLifetime,
    double? roundDuration,
    double? bombChance,
    CheckpointSpec? checkpoint,
    StarThresholds? starThresholds,
  }) {
    return LevelConfig(
      fallSpeed: fallSpeed ?? this.fallSpeed,
      spawnRate: spawnRate ?? this.spawnRate,
      maxObjects: maxObjects ?? this.maxObjects,
      shapes: shapes ?? this.shapes,
      forbiddenChanges: forbiddenChanges ?? this.forbiddenChanges,
      forbiddenInterval: forbiddenInterval ?? this.forbiddenInterval,
      idleDecaySeconds: idleDecaySeconds ?? this.idleDecaySeconds,
      warmupDurationSeconds: warmupDurationSeconds ?? this.warmupDurationSeconds,
      forbiddenGuaranteeInterval:
          forbiddenGuaranteeInterval ?? this.forbiddenGuaranteeInterval,
      spawnOverlapRadius: spawnOverlapRadius ?? this.spawnOverlapRadius,
      objectSize: objectSize ?? this.objectSize,
      waveSize: waveSize ?? this.waveSize,
      objectLifetime: objectLifetime ?? this.objectLifetime,
      roundDuration: roundDuration ?? this.roundDuration,
      bombChance: bombChance ?? this.bombChance,
      checkpoint: checkpoint ?? this.checkpoint,
      starThresholds: starThresholds ?? this.starThresholds,
    );
  }
}
