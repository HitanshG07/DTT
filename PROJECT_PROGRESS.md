# Don't Tap That 2.0 — Project Progress Ledger

> **Accountability across all phases.** What was actually done in each phase (specific), and
> what remains. Companions: `DTT_2.0_ROADMAP.md` (what/why), `DTT_2.0_MILESTONES.md` (gates),
> `PHASE_1_PROGRESS.md` (deep Phase-1 handoff).
>
> **Last updated:** 2026-06-22.
> **Overall status:** Phases 0–4 ✅ complete & green (4C device-verified) · Phase 5 in progress —
> 5.0 docs ✅, Part A dev-unlock ✅ (113 tests green); **Hotfix H** (humane caps, L21–30) planned &
> documented, code next.

| Phase | Title | Status |
|---|---|---|
| 0 | Baseline bug-fixes | ✅ Done & committed (GitHub `main`) |
| 1 | Engine pivot → Spatial Burst | ✅ Code complete, analyze clean, 81/81 tests green · ⛔ device-verify + commit pending |
| 2 | Bomb + White Blast + time economy | ✅ Code complete, analyze clean, 88/88 tests green · ⛔ device-verify + commit pending |
| 3 | Memory checkpoints | ✅ Code complete, analyze clean, 95/95 tests green · ⛔ device-verify + commit pending |
| 4 | 30-level generated map + 3-star mastery | ✅ DONE — **4A + 4B + 4C-1 + 4C-2 complete & device-verified** (engine + stars + map + full nav loop; analyze clean, 108/108 green; emulator-verified) |
| 5 | Modes, Modifiers & Accelerated Progression (replanned) | 🟡 In progress — 5.0 docs ✅, Part A dev-unlock ✅ (113 green); Hotfix H (humane caps L21–30) + 5A–5H pending |

---

## ✅ Phase 0 — Baseline bug-fixes (DONE, committed)

**What was done (7 runtime fixes the unit tests didn't catch + regression tests):**
1. `DttGame` is constructed **once** (in `didChangeDependencies`, not `build()`), so
   pause/resume no longer destroys & recreates the game (pool wipe, re-rolled forbidden,
   reset ScoreManager).
2. **One `ScoreManager`** shared by `DttGame` and `RealGameController` — accuracy & longest
   streak on the Game Over screen are now real.
3. **Intro-selected forbidden == in-game forbidden** — removed the onLoad re-roll; HUD/AVOID,
   engine, and Forbidden Intro all agree.
4. **Combo resets on wrong tap; a missed correct object drops combo one step** (forbidden
   miss exempt).
5. **Identical off-white shape colour** — colour never reveals which shape is forbidden;
   memory is the only cue.
6. **HUD overflow fixed** — `kHudHeight` raised to 72px (was overflowing ~13px).
7. Spawn-overlap warning demoted to a debug-only `assert` log (no release spam).

**Tests added:** stats-wiring, forbidden-iff-shape invariant, HUD no-overflow. Baseline = 67
tests green.

**Deferred (non-blocking):** 3 cosmetic items in `VISUAL_TODO.md` (triangle centroid, milestone
banner z-order, HUD badge spacing). One triangle tweak is an uncommitted working-tree edit.

---

## ✅ Phase 1 — Engine pivot: Spatial Burst (CODE COMPLETE; device-verify + commit pending)

**Goal delivered:** falling loop → static **shrinking-lifetime** objects, **2D wave** spawning,
and a **round countdown timer**. Round ends on **lives==0 OR timer==0** (lives→time economy is
Phase 2). Architecture: **fork, don't mutate** — `FallingObject` left untouched as the dormant
Zen engine; `DttGame` retyped to drive `BurstObject`.

**Specifically done — new files:**
- `config/game_mode.dart` — `enum GameMode { burst, zen }`.
- `components/burst_object.dart` — static object; lifetime drains in `update`; visual scale =
  remaining/lifetime; `onExpired` fires exactly once; **tap hitbox pinned at max(objectSize,48)
  while the visual shrinks** (NFR-07); `lifeFraction` getter.
- `timer_manager.dart` — pure-Dart round clock; seeds/decrements `GameState.timeRemaining`;
  `isExpired`; `addTime()` (penalty/reward hook ready for Phase 2/3).
- `overlays/countdown_bar.dart` — thin HUD bar bound to `timeRemaining`; amber below 20%.

**Specifically done — modified files:**
- `object_pool.dart` → generic `ObjectPool<T extends PositionComponent>` (serves BurstObject
  now, FallingObject in Phase 5).
- `game_state.dart` → added `timeRemaining` notifier (+ disposed).
- `config/level_config.dart` → added `waveSize`, `objectLifetime`, `roundDuration` (defaulted).
- `config/level_registry.dart` → per-level tuning; roundDuration L1–L4 = 60s, L5 = 75s;
  waveSize 4→6; objectLifetime 3.0→1.6.
- `config/game_constants.dart` → burst play-area top/bottom insets (keep objects off the HUD).
- `dtt_game.dart` → burst rewire: `ObjectPool<BurstObject>`, `_createBurstObject`,
  `_timerManager`, timer tick after warmup + round-end on expiry, `_spawnWave()` (tickWave +
  generate2DPosition + 2D scatter, capped by maxObjects/pool), callbacks retyped,
  `_onMissed`→`_onExpired`, proximity uses `whereType<BurstObject>()`.
- `spawn_manager.dart` → **added** `tickWave()` (4–6/wave; preserves warmup FR-18, FR-19
  guarantee, forbidden-iff-shape FR-13) and `generate2DPosition()` (pure-Dart 2D overlap
  avoidance). 1.x `tick()`/`generateX()` kept for Phase-5 Zen.
- `screens/game_screen.dart` → `timeRemaining` listener navigates to Game Over at 0 (guarded
  against initial 0.0); places `CountdownBar` below HUD; removes listener on dispose.

**Tests:** +14 (burst_object 3, timer_manager 5, spawn_manager wave/2D 6); object_pool typed;
one over-reaching forbidden-change L5 test trimmed to in-round rotations (documented). **Total
81/81 green, analyze clean.**

**Remaining for Phase 1:** ⛔ on-device/emulator verification (M1.9), then commit to a branch.

---

## ✅ Phase 2 — Bomb + White Blast + time economy (CODE COMPLETE; device-verify + commit pending)

**Done & verified (analyze clean, 88/88 tests green):**
- `ShapeType.bomb` + self-colouring salient `BombShape` (never the forbidden shape — excluded
  from every `LevelConfig.shapes`; spawned only via `LevelConfig.bombChance`).
- `BurstObject` bomb routing: `isBomb`, `onBombTap` callback, tap dispatch
  (bomb → onBombTap, else forbidden → onWrongTap, else onCorrectTap).
- `SpawnManager.tickWave` injects bombs on non-guaranteed slots (`bombChance` per level: L1 0 →
  L5 0.20; `>0` guard keeps bomb-free configs deterministic).
- **Time economy:** forbidden tap −2s, bomb tap −4s, both reset combo via
  `ScoreManager.onPenaltyTap()` (NO life loss); `onWrongTap` still loses a life for 1.x/Zen.
  Round ends when the clock drains.
- `WhiteBlastEffect`: single ~150ms pulse, opacity hard-capped ≤0.75, no strobe; `reduced` →
  soft edge vignette.
- **"Reduce flashing" toggle (mandatory, shipped with the blast):** Settings switch (key
  `dtt_reduce_flashing`) → `forbidden_intro_screen` reads pref → `RealGameController.reduceFlashing`
  → `DttGame._reduceFlashing` → `WhiteBlastEffect(reduced:)`.
- Bomb-expiry exempt from combo drop (letting a bomb expire = correct).
- **Fixed a Phase-1 gap:** burst timer-end now persists best score (lives never hit 0 in burst,
  so LifeManager's save never fired).
- Tests: `phase2_bomb_test` (bomb fills slots / never forbidden / invariant; onPenaltyTap no
  life loss; onWrongTap still loses life) + `white_blast_effect_test` (opacity cap, reduced flag,
  single-pulse auto-remove).

**Remaining:** ⛔ device/emulator verification + commit.

**Known cosmetic (deferred):** HUD still shows 3 lives hearts though lives never change in burst
(time is the resource).

## ✅ Phase 3 — Memory checkpoints (CODE COMPLETE; device-verify + commit pending)

**Done & verified (analyze clean, 95/95 tests green):**
- `CheckpointSpec` + `CheckpointPrompt` (pure-Dart config); `LevelConfig.checkpoint`
  (disabled by default). Registry: L1–L2 off, L3/L4 set-recall (interval 20s/18s), L5
  order-recall (15s).
- `CheckpointManager` (pure Dart): `assignToken` (distinct tokens, capped per window),
  `tick`/`isDue` (interval elapsed AND ≥1 special shown), `buildPrompt` (seen + distractors,
  shuffled), `resolve` (+5s correct / −3s wrong; set- and order-recall grading), `reset`.
- `BurstObject.token` + centred glyph render (scales with the shape) + `reconfigure` reset.
- `GameState.checkpointActive` notifier (disposed). `DttGame` gates the round timer +
  checkpoint clock on it.
- `DttGame` wiring: one special token per wave (rides a normal target, never bomb/forbidden;
  token recorded only when actually rendered), `_openCheckpoint` (freeze + `paused=true`),
  public `resolveCheckpoint(selected)` (apply time delta, resume, end round if drained).
- `MemoryCheckpointOverlay` Flutter modal (tap-to-select chips, order badges when
  orderMatters, SUBMIT gated on recallCount); `game_screen` shows it on `checkpointActive`
  and calls `resolveCheckpoint`.
- Tests: `checkpoint_manager_test` (7) — token handout, disabled no-op, due gating, options
  contain all seen, set-recall any-order, wrong-membership penalty, order-recall.
- **Regression fix:** added `LevelConfig.copyWith`; `forbidden_change_test` now builds its
  games with checkpoints disabled (checkpoints legitimately pause the game waiting for a
  recall answer, which those headless rotation tests don't provide).

**Remaining:** ⛔ device/emulator verification + commit.

## ✅ Phase 4 — 30-level generated map + 3-star mastery (4A+4B+4C complete & device-verified)

Split into 4A (difficulty engine) → 4B (stars/progression) → 4C (map UI). Design: 6 worlds × 5
= 30; breakpoints bombs@4 / checkpoints@9 / rotation@13 / order-recall@21; sawtooth curve;
flavors; human-possible hard caps; star override map. See `DTT_2.0_ROADMAP.md §7`.

**✅ Phase 4A — Difficulty engine (DONE; analyze clean, 94/94 green):**
- `StarThresholds` (`starsFor` 0–3); `LevelConfig.starThresholds` (+ copyWith).
- `LevelGenerator` (pure Dart): 6×5 worlds, **sawtooth** difficulty (band climbs 0.12/world,
  reaches 1.0 only at L30, strictly rises within a world, dips at world starts), per-dial
  interpolation, **flavors** (calm/swarm/minefield/recall/shuffle/gauntlet), **human-limit
  clamps** (lifetime ≥1.1s, bomb ≤0.30, rotation ≥12s, recall ≤4, size 32–52), and a
  **mandatory star override `Map<int,…>`**.
- `LevelRegistry.forLevel` → generator; **30 levels**; `_starOverrides` hand-tunes L29/L30
  (placeholder, tune on-device).
- Tests reworked to **curve invariants**: `level_config_test` (30 levels, sawtooth, breakpoints,
  caps, shape monotonicity, star ordering, override-wins); `forbidden_change_test` made
  config-driven (rotation now ≥L13, so it builds an explicit rotating config via `copyWith`).

**✅ Phase 4B — Stars & progression (DONE; analyze clean, 101/101 green):**
- `GameController.level` added (Real stores it, Mock returns 1).
- `ProgressService`: per-level best stars under `dtt_stars_level_<n>`, **best-of** semantics;
  `isUnlocked(n)` (L1 always; else N−1 ≥1★); `getAllStars(count)` for the map.
- Game Over computes stars (`levelConfig.starThresholds.starsFor(score)`), **saves best-of**,
  and **displays a 3-star row**.
- Tests: `progress_service_test` (7) — best-of, no-downgrade, unlock gating, getAllStars.
- ⛔ Remaining: device verification (a level awards/saves stars, unlock persists).

**🟡 Phase 4C — Map + navigation:** **split into two safe parts; 4C-1 DONE, 4C-2 remains.**
- **✅ 4C-1 — Map screen (render + data):** DONE. Built `lib/screens/map_screen.dart` — a
  chaptered winding-path: 6 world chapters (banner + per-world tint/name from the flavour arc),
  30 serpentine nodes, vertical scroll with auto-scroll to the current (highest-unlocked) node.
  Each node reads locked/unlocked + 3-pip star count from `ProgressService.getAllStars(30)`
  (unlock = previous level ≥1★; L1 always open); locked nodes show a lock icon instead of the
  number. Registered on its own `/map` route in `app.dart`; **existing nav untouched** — node
  taps are an inert `_onNodeTap` (flow lands in 4C-2). Tests: `test/widget/map_screen_test.dart`
  (5 widget tests). Gate **PASSED**: analyze clean, 106/106 green.
- **✅ 4C-2 — Navigation flow:** CODE-COMPLETE (device verify pending). Wired the full loop
  `Start → Map → node → forbidden-intro(level) → game → Game Over → Map`:
  - `StartScreen` PLAY → `/map` (the map is now the hub).
  - `MapScreen._onNodeTap(level)` → `pushNamed('/forbidden-intro', arguments: {'level': level})`,
    and reloads progress on return so new stars/unlocks appear.
  - `app.dart` `/forbidden-intro` route reads `{'level': n}` (defaults to 1) → passes to
    `ForbiddenIntroScreen(level:)` → `RealGameController(level: n)` (loads that `LevelConfig`).
  - `GameOverScreen`: RETRY replays the **same** level (`level: _controller.level`); the second
    button is now **MAP** → `pushNamedAndRemoveUntil('/map', (r)=>r.isFirst)` (Start stays at root,
    map rebuilt so earned stars/unlocks show).
  - Stars already persist via `ProgressService.saveStars(_controller.level, …)` at Game Over.
  - Tests: `map_navigation_test.dart` (tap→intro with level arg; locked node inert) + updated
    `map_screen_test`/`start_screen_test`. Gate: analyze clean, **108/108 green**.
  - ✅ Device-verified on emulator-5554 (`dtt_shots/H03`–`H06`): PLAY→Map; tapping Level 2 →
    its forbidden-intro (circle) → Level-2 game; Game Over showed the **MAP** button + 0 stars
    for a 0 score; MAP returned to a refreshed map. Gating proven both ways — L1 ★★★ ⇒ L2
    unlocked, and a 0-score L2 run left L3 **locked**. L1 ★★★ + BEST 1520 loaded on a fresh
    launch (progress survives restart).

## 🟡 Phase 5 — Modes, Modifiers & Accelerated Progression (IN PROGRESS — 5.0 + Part A done)

**Replanned 2026-06-22.** The old "revive falling as Zen + chores" Phase 5 was **dropped** as
low-value (`GameMode.zen` stays dormant, not surfaced). New scope finishes the game around its
identity — a go/no-go inhibition + visual-search + working-memory trainer. Full narrative in
`DTT_2.0_ROADMAP.md §8`; gated milestone tables in `DTT_2.0_MILESTONES.md` (Phase 5).

**Decisions locked in:** modifiers are **campaign-flavor only** (no player toggles); **Endless =
pure survival, no modifiers**; **accelerated "tasting menu"** introduces every modifier by ~L9.

**Sub-phases:**
- **5.0 Documentation** — ✅ done (ROADMAP §8, MILESTONES Phase 5, this section).
- **Part A — Dev unlock-all** — ✅ done (`DebugFlags.unlockAllLevels` + red `[DEV UNLOCK]` badge; 113 tests green).
- **Hotfix H — Humane difficulty caps (L21–30)** — 🔵 planned & documented, code not started. Dev-unlock
  playtest found L30 humanly impossible; ease worlds 5–6 only (L1–20 untouched): lifetime ≥1.7s,
  size 42–52px, ≥50% visual-shrink floor (`LevelConfig.minVisualScale`), ≤7 on-screen, waves ≤6,
  spawn ≤1.4/s. Also: **≤2 simultaneous modifiers** guardrail (for 5B/5H) + **Bug-MS** score-50 centre pop.
- **5A — Practice Mode** — ⛔ (long-press a node; no stars/best saved).
- **5B — Modifier framework + `blind`** — ⛔ (`Set<RoundModifier>` on `LevelConfig` + first-encounter coachmark).
- **5C — Endless Burst** — ⛔ (score-gated continuous ramp; survival-by-time; separate best key).
- **5D — `dualTarget`** — ⛔ (two forbidden shapes; + `blind+dualTarget` combo smoke-test).
- **5E — `ruleFlip`** — ⛔ (cued inversion; **bomb immune**; REVERSE cue + reduce-flashing fallback).
- **5F — `taskSwitch`** — ⛔ (scheduled flipping, reuses 5E).
- **5G — `nBack`** — ⛔ (paused checkpoint; bounded wave-history queue; standard economy).
- **5H — Progression rewrite + ship copy** — ⛔ (`getModifiersForLevel`, new world themes, W1–3/W4–6 playtests).

**Parked as future ideas:** feedback/feel (mistake replay, heatmap, stop-signal, focus-sprint),
Calibration, Calm mode, Daily challenge, custom builder, seed codes, cosmetics, full tutorial.

---

## Cross-cutting still open (tracked all phases)
- **Audio:** only `test.ogg` exists; real SFX deferred to Phase 5 (play calls null-safe).
- **Accessibility:** 48px hitbox floor ✅ (P1); Reduce-flashing toggle due P2.
- **Persistence:** best score ✅ → + per-level stars (P4) → + settings flags (P2).
- **Marketing honesty:** paradigm-based language only; no "clinically proven" claims (P5 copy).

## Immediate next action
Phases 0–4 complete & green plus this session's post-Phase-4 polish (HUD redesign, constellation
map, lifecycle/overlapping-tap/timer-start bug fixes). **Phase 5.0 docs ✅, Part A dev-unlock ✅
(113 tests green).** Next code step: **Hotfix H — humane difficulty caps (L21–30 only)** —
conditional caps + data-driven `LevelConfig.minVisualScale`, plus Bug-MS (score-50 centre pop).
Then 5A — Practice Mode. _(Hotfix H is planned & documented; code deferred per current instruction.)_
