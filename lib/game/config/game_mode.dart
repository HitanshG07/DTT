/// The active gameplay engine for a round.
///
/// 2.0 forks the engine without throwing away the verified 1.x falling loop:
///   * [burst] — the 2.0 "Spatial Burst" mode: static objects that appear at a
///     2D spot and shrink in place as their lifetime drains; a round countdown
///     timer ends the round. This is the active mode for Phases 1–4.
///   * [zen] — the preserved 1.x falling engine ([FallingObject]): objects fall
///     top→bottom, lives end the round, no timer. Kept intact and dormant;
///     surfaced as an optional "Endless / Zen" mode in Phase 5.
///
/// Reference: DTT_2.0_ROADMAP.md §2.1 (fork, don't mutate), §8 (Phase 5).
enum GameMode {
  /// 2.0 Spatial Burst — shrinking-lifetime objects, wave spawning, round timer.
  burst,

  /// 1.x classic falling — preserved engine, lives-based, no timer (Phase 5 UI).
  zen,
}
