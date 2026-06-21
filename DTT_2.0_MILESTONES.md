# Don't Tap That 2.0 — Milestones

> **Companion to** `DTT_2.0_ROADMAP.md`. The roadmap says *what* each phase builds and *why*;
> this file is the **ordered checklist of gates** to march through. Tick a milestone only when
> its **Done-when** is fully true. Never start a milestone whose predecessor is unchecked.
>
> **Legend:** `[ ]` not started · `[~]` in progress · `[x]` done & verified.
> **Hard rule:** every phase ends on a device check + `flutter analyze` clean + `flutter test` green.

---

## Phase 0 — Baseline lock-in  *(code done, not yet committed)*

| # | Milestone | Done-when |
|---|---|---|
| **M0.1** | `[ ]` Commit Phase-0 fixes to a branch | 7 fixes + regression tests on a `phase-0` (or feature) branch; working tree clean |
| **M0.2** | `[ ]` Green baseline | `flutter analyze` clean · `flutter test` all green |
| **M0.3** | `[ ]` Tag the baseline | A git tag / note marking "verified pre-2.0 engine" so Phase 5's Zen mode has a known-good reference |

**Phase 0 gate → Phase 1:** M0.1–M0.3 all `[x]`. *(VISUAL_TODO.md cosmetics are non-blocking.)*

---

## Phase 1 — Engine pivot: Spatial Burst

| # | Milestone | Done-when |
|---|---|---|
| **M1.1** | `[ ]` `GameMode { burst, zen }` enum added; `DttGame` branches on it | Existing falling path runs unchanged under `GameMode.zen`; `burst` selectable in code |
| **M1.2** | `[ ]` `BurstObject` component (forked from `FallingObject`) | Static object; `_remaining -= dt`; visual scale = `remaining/lifetime`; `onExpired` fires once; **hitbox stays ≥48px while shrinking** |
| **M1.3** | `[ ]` `SpawnManager` emits 2D waves | `tickWave` returns 4–6 decisions; `generate2DPosition` respects overlap radius; `isForbidden` **iff** `shape == forbiddenShape` holds across the wave; `SpawnScript` still single-item |
| **M1.4** | `[ ]` `GameState.timeRemaining` added (+ disposed) | New `ValueNotifier<double>`; existing notifiers untouched |
| **M1.5** | `[ ]` `TimerManager` (pure Dart) | Counts `roundDuration` down, writes `timeRemaining`, `isExpired`; round ends on **lives==0 OR timer==0** |
| **M1.6** | `[ ]` `LevelConfig` gains `waveSize` / `objectLifetime` / `roundDuration` | One tuned value per level; falling fields untouched; zero logic change |
| **M1.7** | `[ ]` HUD countdown readout | Thin top bar bound to `timeRemaining` |
| **M1.8** | `[ ]` Phase-1 tests written & green | `burst_object_test`, extended `spawn_manager_test`, `timer_manager_test`, extended `object_pool_test`; **all Phase-0 regressions still green** |
| **M1.9** | `[ ]` Device verification | Waves scatter, shrink, vanish; correct tap scores; expiry drops combo; timer ends round; forbidden matches intro |

**Phase 1 gate → Phase 2:** M1.1–M1.9 `[x]`; `analyze` clean; `test` green; verified on emulator.

---

## Phase 2 — Bomb + White Blast + time economy

| # | Milestone | Done-when |
|---|---|---|
| **M2.1** | `[ ]` `ShapeType.bomb` + painter | Black, always-salient; **never** selected/rotated as forbidden (excluded in `ForbiddenManager` + `SpawnManager`) |
| **M2.2** | `[ ]` Time economy replaces lives loss | forbidden tap −2s +reset combo; bomb tap −4s +reset; correct +score/+combo; round ends at `timeRemaining==0` → save |
| **M2.3** | `[ ]` `WhiteBlastEffect` | Single ~150ms pulse, **≤75% opacity, no strobe/repeat**, heavy haptic + shatter sound |
| **M2.4** | `[ ]` "Reduce flashing" toggle (mandatory, same PR) | Persisted setting; when on, blast → static edge-vignette (no full-screen flash) |
| **M2.5** | `[ ]` Phase-2 tests green | bomb-never-forbidden; −2s/−4s via `timeRemaining` not lives; blast opacity cap + single-fire; reduceFlashing routes to vignette |
| **M2.6** | `[ ]` Device verification | Bombs always dangerous; mis-taps cost time; timer-zero saves; flash is one capped pulse; toggle visibly changes & persists |

**Phase 2 gate → Phase 3:** M2.1–M2.6 `[x]`; `analyze` clean; `test` green; verified on emulator.

---

## Phase 3 — Memory checkpoints

| # | Milestone | Done-when |
|---|---|---|
| **M3.1** | `[ ]` Special token-carrying targets | A few specials per window render a glyph (number/letter/animal) and are recorded as "seen" |
| **M3.2** | `[ ]` `GameState.checkpointActive` pauses the timer | When true, `TimerManager` does not decrement; play freezes |
| **M3.3** | `[ ]` `MemoryCheckpointOverlay` modal | Opens at checkpoint; set-recall (+order-recall at higher levels); correct +5s, wrong −3s |
| **M3.4** | `[ ]` Checkpoint cadence from `LevelConfig` | `CheckpointSpec` (count, recall type, reward/penalty) drives it |
| **M3.5** | `[ ]` Phase-3 tests green | timer frozen during checkpoint; +5/−3 applied; recall options == seen set (no phantoms); order variant checks sequence |
| **M3.6** | `[ ]` Device verification | Specials carry tokens; checkpoint freezes & opens modal; recall adjusts time; resume is clean |

**Phase 3 gate → Phase 4:** M3.1–M3.6 `[x]`; `analyze` clean; `test` green; verified on emulator.

---

## Phase 4 — Progression: 30-level generated map + 3-star mastery

Split into three gated sub-phases: **4A** difficulty engine → **4B** stars/progression →
**4C** map UI. Structure: 6 worlds × 5 = 30; breakpoints bombs@4 / checkpoints@9 / rotation@13
/ order-recall@21; sawtooth curve; flavors; human-possible hard caps.

### Phase 4A — Difficulty engine (pure logic)
| # | Milestone | Done-when |
|---|---|---|
| **M4A.1** | `[ ]` `StarThresholds` + `LevelConfig.starThresholds` | `starsFor(score)` returns 0–3 by cutoff; field on config + `copyWith` |
| **M4A.2** | `[ ]` `LevelGenerator` (pure Dart) | 6×5 worlds, sawtooth curve, per-dial lerp, flavor modifiers, **human-limit clamps**, **mandatory override `Map<int,…>`** |
| **M4A.3** | `[ ]` `LevelRegistry.forLevel` → generator, 30 levels | API preserved; `forLevel(n)` for 1..30; clamps out of range |
| **M4A.4** | `[ ]` Affected tests reworked | `level_config_test` → curve invariants; `forbidden_change_test` → config-driven rotation (rotation now ≥L13) |
| **M4A.5** | `[ ]` Generator tests green | size strictly decreases; no bombs <L4; rotation only ≥L13; order-recall ≥L21; caps respected (lifetime≥1.1, recall≤4, bomb≤0.30, rot≥12); 30 levels; override map wins |

**4A gate → 4B:** M4A.1–M4A.5 `[x]`; `analyze` clean; `test` green.

### Phase 4B — Stars & progression
| # | Milestone | Done-when |
|---|---|---|
| **M4B.1** | `[ ]` Star evaluation at round end | Final score → stars via that level's thresholds |
| **M4B.2** | `[ ]` Per-level star persistence | Stored per level, **best-of** (never lose a star), survives relaunch |
| **M4B.3** | `[ ]` Unlock gating | Level N unlocked iff N−1 has ≥1★; L1 always open; **no energy/attempt limits** |
| **M4B.4** | `[ ]` Game Over shows stars earned | Stars rendered on the result screen |
| **M4B.5** | `[ ]` Tests + device verify | threshold→stars, unlock-gating, persistence tests green; verified on device |

**4B gate → 4C:** M4B.1–M4B.5 `[x]`; `analyze` clean; `test` green; verified on emulator.

### Phase 4C — Map + navigation (UI), split into two safe parts

#### Phase 4C-1 — Map screen (render + data, no flow changes)
| # | Milestone | Done-when |
|---|---|---|
| **M4C1.1** | `[ ]` Winding-path map screen | 30 nodes, 6 world segments (banners/tint), scroll, auto-scroll to current |
| **M4C1.2** | `[ ]` Locks + stars from progress | Each node's locked/unlocked + star count read from `ProgressService` (`getAllStars`/`isUnlocked`) |
| **M4C1.3** | `[ ]` Reachable, flow untouched | Map on its own route; existing nav unchanged; node taps a no-op for now |
| **M4C1.4** | `[ ]` Widget test + green | Renders 30 nodes with correct locks/stars from mocked prefs; `analyze` clean, `test` green |

**4C-1 gate → 4C-2:** M4C1.1–M4C1.4 `[x]`; `analyze` clean; `test` green.

#### Phase 4C-2 — Navigation flow (wire it in)
| # | Milestone | Done-when |
|---|---|---|
| **M4C2.1** | `[ ]` Level threaded through | `forbidden-intro(level)` → `RealGameController(level:)`; node tap launches that level |
| **M4C2.2** | `[ ]` Full loop | `Start → Map → node → game → Game Over → back to Map`; Game Over returns to Map |
| **M4C2.3** | `[ ]` Device verification | Picking a node plays that level; clearing awards/saves stars & unlocks next; survives restart |

**4C-2 gate → Phase 5:** M4C2.1–M4C2.3 `[x]`; `analyze` clean; `test` green; verified on emulator.

---

## Phase 5 — Classic Falling as optional mode + polish

| # | Milestone | Done-when |
|---|---|---|
| **M5.1** | `[ ]` Surface `GameMode.zen` ("Endless / Zen") | Dormant falling path reachable via mode select on Start/Map; lives, no timer; no new engine work |
| **M5.2** | `[ ]` Both modes share one `GameState` contract | No divergence; Zen ends on lives==0, Burst on timer==0 |
| **M5.3** | `[ ]` Resolve `VISUAL_TODO.md` cosmetics | All 3 deferred items fixed & verified |
| **M5.4** | `[ ]` Audio asset pass | Real `.ogg` files in `assets/audio/`; SFX/pitch-ladder audibly working |
| **M5.5** | `[ ]` Marketing-honesty copy pass | Store/UI copy paradigm-based; **no** "clinically proven" claims |
| **M5.6** | `[ ]` Final regression + ship gate | Mode switch routes correctly; full suite green; both modes stable on device |

**Ship gate:** M5.1–M5.6 `[x]`; `analyze` clean; full `test` green; both modes verified on device.

---

## Tracking rules
1. **One phase in flight at a time.** Don't open Phase N+1 milestones until Phase N's gate row is fully `[x]`.
2. **Every milestone is device-or-test verifiable** — if you can't state its Done-when as a pass/fail check, it isn't a milestone yet.
3. **Guardrails are not milestones to skip:** the 48px hitbox floor (M1.2), the mandatory flashing toggle shipping *with* the blast (M2.4), one-ScoreManager/one-forbidden-source, **no hidden physics manipulation (data integrity — Phase 4A caps/clamps + rejected comeback assist)**, and **generated difficulty stays hand-overridable** all survive every phase.
4. Update each `[ ]` → `[~]` → `[x]` as you go; the gate rows are the only thing that authorizes the next phase.
