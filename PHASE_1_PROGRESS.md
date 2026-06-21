# Phase 1 — Engine Pivot (Spatial Burst): Progress & Handoff

> **Golden rule:** keep this doc current. Before any long work risks running out of
> context, capture what's done and what's left here so work can resume cleanly.
>
> **Companion docs:** `DTT_2.0_ROADMAP.md` (the what/why), `DTT_2.0_MILESTONES.md` (the gates).
> **Status as of this checkpoint:** code complete; `flutter analyze` clean; `flutter test`
> **81/81 green** (was 67 at Phase-0 baseline → +14 Phase-1 tests). **Not yet committed.**
> **Only remaining Phase-1 gate: on-device/emulator verification (M1.9).**

---

## Goal of Phase 1
Replace the falling-object loop with the 2.0 **Spatial Burst** loop, *without* deleting the
verified 1.x engine:
- Objects no longer fall — they appear at a 2D spot and **shrink in place** as a lifetime
  drains (shrink = the timer). Expiry replaces "fell off the bottom".
- Spawns come in **waves of 4–6** scattered in 2D, not one-at-a-time in 1D.
- A **round countdown timer** is introduced; the round ends on **lives==0 OR timer==0**
  (the lives→time economy itself is Phase 2).

**Architecture decision (locked in):** *fork, don't mutate.* `FallingObject` is left
**byte-for-byte untouched** as the dormant "Zen" engine (surfaced in Phase 5). Burst is the
only active mode now. `DttGame` was retyped to drive `BurstObject` (DttGame is the expected
place for change; `FallingObject` is the protected file).

---

## DONE — files created
| File | Purpose |
|---|---|
| `lib/game/config/game_mode.dart` | `enum GameMode { burst, zen }` |
| `lib/game/components/burst_object.dart` | Forked from FallingObject: static, lifetime countdown + shrink, `onExpired` fires once, **hitbox pinned at max(objectSize,48)** while the visual shrinks (NFR-07), `lifeFraction` getter for tests |
| `lib/game/timer_manager.dart` | Pure-Dart round clock: seeds + counts down `GameState.timeRemaining`, `isExpired`, `addTime()` (hook for Phase 2/3 time economy) |
| `lib/overlays/countdown_bar.dart` | Thin HUD progress bar bound to `timeRemaining`; turns amber below 20% |
| `test/game/burst_object_test.dart` | 3 tests: lifeFraction tracks remaining/lifetime; onExpired exactly once; hitbox stays 48px while shrinking |
| `test/game/timer_manager_test.dart` | 5 tests: seed, decrement+publish, clamp-at-0/expired, no-op-when-expired, addTime ± |

## DONE — files modified
| File | Change |
|---|---|
| `lib/game/object_pool.dart` | Generalized to `ObjectPool<T extends PositionComponent>` (serves BurstObject now, FallingObject in Phase 5). No longer imports falling_object |
| `lib/game/game_state.dart` | Added `timeRemaining : ValueNotifier<double>` (+ disposed) |
| `lib/game/config/level_config.dart` | Added `waveSize` (def 5), `objectLifetime` (def 2.5), `roundDuration` (def 60) — all defaulted so 1.x const configs/tests still compile |
| `lib/game/config/level_registry.dart` | Per-level values. **roundDuration: L1–L4 = 60s, L5 = 75s.** waveSize 4→6, objectLifetime 3.0→1.6 across levels |
| `lib/game/config/game_constants.dart` | `kBurstPlayAreaTopInset = 88` (clears HUD+bar), `kBurstPlayAreaBottomInset = 72` |
| `lib/game/dtt_game.dart` | **Big rewire:** imports burst_object/game_mode/timer_manager; `gameMode` field (def burst); `ObjectPool<BurstObject>`; `_createBurstObject`; `_timerManager` seeded in onLoad; update() ticks timer after warmup and ends round on expiry; new `_spawnWave()` (tickWave + generate2DPosition, 2D scatter, maxObjects/pool cap); callbacks retyped to BurstObject; `_onMissed`→`_onExpired`; proximity uses `whereType<BurstObject>()` |
| `lib/game/spawn_manager.dart` | **Added** `tickWave()` (emits config.waveSize decisions; warmup→single non-forbidden, FR-18; one guaranteed forbidden when overdue, FR-19; forbidden-iff-shape, FR-13) and `generate2DPosition()` (2D overlap-avoidance, pure Dart, record return). 1.x `tick()`/`generateX()` kept intact for Phase-5 Zen |
| `lib/screens/game_screen.dart` | Listens to `timeRemaining` → navigates to Game Over on timer==0 (`_checkTimeUp`, guarded against the initial 0.0 via `_timerStarted`); places `CountdownBar` below HUD; removes the listener in dispose |
| `test/game/object_pool_test.dart` | Typed to `ObjectPool<FallingObject>` (generic pool) |
| `test/game/spawn_manager_test.dart` | +6 tests: wave size 4–6, warmup single/non-forbidden, forbidden-iff-shape across wave, FR-19 one-guaranteed-forbidden, generate2DPosition overlap-avoidance + in-rect bounds |
| `test/game/forbidden_change_test.dart` | L5 no-repeat loop trimmed 5→3 rotations (burst time-boxes the round at 75s; 20/40/60s rotations are the in-round ones). Documented inline |

---

## Milestones (from DTT_2.0_MILESTONES.md)
- M1.1 GameMode enum ............................. ✅
- M1.2 BurstObject (lifetime/shrink, 48px floor) .. ✅
- M1.3 SpawnManager wave + 2D ..................... ✅
- M1.4 GameState.timeRemaining ................... ✅
- M1.5 TimerManager .............................. ✅
- M1.6 LevelConfig + registry fields ............. ✅
- M1.7 DttGame rewire + HUD countdown ............ ✅
- M1.8 Tests written; Phase-0 regressions green .. ✅ (81/81)
- **M1.9 analyze+test green ✅ → DEVICE VERIFICATION ⛔ PENDING (only open item)**

---

## LEFT TO DO
1. **M1.9 device verification (only thing blocking the Phase-1 gate).** Run:
   `flutter run -d emulator-5554` and confirm:
   - Waves of off-white shapes appear scattered in 2D, **shrink**, and vanish.
   - Tapping a correct shape scores; letting a correct one shrink away drops the combo.
   - The **countdown bar** drains; at 0 the round ends → Game Over (also still ends on lives==0).
   - The forbidden cue still matches the Forbidden Intro; objects never spawn behind the HUD.
2. **Commit Phase 1** to a branch once device-verified (not committed yet).
3. Then **Phase 2** (Bomb + White Blast + lives→time economy). `TimerManager.addTime()` is
   already in place as the penalty/reward hook.

## Known notes / deferred (not Phase-1 blockers)
- **Audio still silent** — `assets/audio/` has only `test.ogg`; real SFX land in Phase 5
  (play calls are null-safe). Carried in `DTT_2.0_ROADMAP.md §10`.
- **Zen mode not wired into DttGame yet** — by design. `FallingObject` + falling
  `tick`/`generateX` are preserved and dormant; Phase 5 surfaces them via `GameMode.zen`.
- **Round durations** (L5=75s etc.) were set partly to contain the existing forbidden-change
  integration timelines; real tuning is owned by Phase 4 (config-driven, §3.3).
- 3 cosmetic items remain in `VISUAL_TODO.md` (non-blocking; one triangle tweak is the
  uncommitted working-tree change from before Phase 1).

## How to resume quickly
`flutter analyze` (clean) → `flutter test` (81 green) → device-verify the list above →
commit → start Phase 2. Engine entry points: `lib/game/dtt_game.dart` (update/_spawnWave),
`lib/game/components/burst_object.dart`, `lib/game/spawn_manager.dart` (tickWave/generate2DPosition).
