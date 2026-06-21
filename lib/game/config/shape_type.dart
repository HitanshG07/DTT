/// Shape types available in the game.
///
/// Seven shape types, introduced progressively across levels:
/// - Level 1: circle, square, triangle
/// - Level 2: + pentagon
/// - Level 3: + star
/// - Level 4: + diamond
/// - Level 5: + cross
///
/// Reference: Section 4.2 -- Shape Set.
enum ShapeType {
  circle,
  square,
  triangle,
  pentagon,
  star,
  diamond,
  cross,

  /// Always-salient hazard (2.0 Burst, DTT_2.0_ROADMAP.md §5). Never selected
  /// as the forbidden shape and never rotates -- it is a *second*, distinct
  /// inhibition channel (always-avoid) alongside the forbidden shape (memory).
  /// Excluded from every [LevelConfig.shapes] pool; spawned only via
  /// [LevelConfig.bombChance]. Rendered with its own salient look (see
  /// BombShape), not the shared off-white fill.
  bomb,
}
