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
| **M4C1.1** | `[x]` Winding-path map screen | 30 nodes, 6 world segments (banners/tint), serpentine layout, scroll, auto-scroll to current node |
| **M4C1.2** | `[x]` Locks + stars from progress | Each node's locked/unlocked + 3-pip star count read from `ProgressService` (`getAllStars`; unlock = prev ≥1★) |
| **M4C1.3** | `[x]` Reachable, flow untouched | Map on its own `/map` route; existing nav unchanged; node taps a no-op (`_onNodeTap`) for now |
| **M4C1.4** | `[x]` Widget test + green | `map_screen_test.dart`: 5 tests (30 nodes, lock on L2 fresh, L2 unlock after L1★, star pips, tap no-op); `analyze` clean, `test` green (106/106) |

**4C-1 gate → 4C-2:** M4C1.1–M4C1.4 `[x]`; `analyze` clean; `test` green. ✅ **PASSED.**

#### Phase 4C-2 — Navigation flow (wire it in)
| # | Milestone | Done-when |
|---|---|---|
| **M4C2.1** | `[x]` Level threaded through | Map node tap → `/forbidden-intro` with `{'level': n}`; `app.dart` reads it → `ForbiddenIntroScreen(level:)` → `RealGameController(level:)`; RETRY replays same level |
| **M4C2.2** | `[x]` Full loop | `Start → Map → node → intro(level) → game → Game Over → Map`; PLAY opens map; Game Over "MAP" button returns (refreshed); map reloads stars on return |
| **M4C2.3** | `[x]` Device verification | **Verified on emulator-5554** (shots `dtt_shots/H0*`): PLAY→Map; tapping Level 2 launched its intro (forbidden=circle) → Level-2 game; Game Over showed the new **MAP** button + score-graded stars; MAP returned to a refreshed map. Gating proven: L1 ★★★ ⇒ L2 unlocked; a 0-score L2 run left L3 **locked**. Persistence: L1 ★★★ + BEST 1520 loaded on a fresh launch (survives restart). |

**4C-2 gate → Phase 5:** M4C2.1–M4C2.3 `[x]`; `analyze` clean; `test` green (108/108); verified on emulator. ✅ **PASSED.**

---

## Phase 5 — Modes, Modifiers & Accelerated Progression

> **Replanned 2026-06-22.** The old "revive falling as Zen + chores" Phase 5 was dropped.
> Scope now: Practice Mode, Endless Burst, a campaign-baked Modifier system (`blind`,
> `dualTarget`, `ruleFlip`, `taskSwitch`, `nBack`), and an accelerated "tasting menu" 30-level
> curve. Full narrative in `DTT_2.0_ROADMAP.md` §8. Sub-phases are gated independently.

### Phase 5.0 — Documentation (do FIRST; docs only, no code)
| # | Milestone | Done-when |
|---|---|---|
| **M5.0.1** | `[ ]` `DTT_2.0_ROADMAP.md` §8 Phase 5 | narrative: modes-vs-modifiers, modifier→hook table, tasting-menu progression, review rulings, the *why* |
| **M5.0.2** | `[ ]` `DTT_2.0_MILESTONES.md` Phase 5 | this section (Part A + 5A–5H tables + gates) |
| **M5.0.3** | `[ ]` `PROJECT_PROGRESS.md` Phase 5 | table row (🔵 planned) + per-phase section listing 5A–5H as not started |
| **M5.0.4** | `[ ]` Cross-check | the three docs + plan agree (sub-phase names, gates, guardrails) |

**5.0 gate → Part A:** M5.0.1–M5.0.4 `[x]`. (Docs only — no build/test gate.)

### Part A — Dev utility: unlock all levels (do first)
| # | Milestone | Done-when |
|---|---|---|
| **MA.1** | `[x]` `DebugFlags.unlockAllLevels` + short-circuit | `ProgressService.isUnlocked` & `MapScreen._isUnlocked` return `true` when on; `getStars` unchanged |
| **MA.2** | `[x]` `[DEV UNLOCK]` ship-safety badge | semi-transparent red corner badge on `MapScreen` iff flag on |
| **MA.3** | `[x]` Tests | progress + map tests assert all-unlocked when on, gated when off |

**Part A gate → 5A:** MA.1–MA.3 `[x]`; `analyze` clean; `test` green.

### Hotfix H — Humane difficulty caps (L21–30 only)
Device-testing L30 (via dev-unlock) showed the late campaign was **humanly impossible**, not
hard-but-fair: objects spawned/despawned too fast and shrank to a dot, so shapes could not be
*identified* in time (the 48 px hitbox stayed tappable, but you couldn't tell forbidden/bomb/correct
apart). **Decision:** raise the human-possible floors so difficulty comes from *cognitive load*, not
sub-human perception/motor demands — scoped to **worlds 5 & 6 only**; **L1–20 stay exactly as they
are**. Two compounding causes fixed in `level_generator.dart` + `burst_object.dart`.

| # | Milestone | Done-when |
|---|---|---|
| **MH.1** | `[ ]` Conditional caps (L21–30) | `humaneCapsFrom = 21` + `topWorlds` gate; lerp endpoints unchanged so L1–20 are byte-for-byte identical; L21–30: lifetime ≥ 1.7 s, spawn ≤ 1.4/s, ≤ 7 on-screen, waves ≤ 6, size 42–52 px |
| **MH.2** | `[ ]` Data-driven shrink floor | `LevelConfig.minVisualScale` (default 0.0 = shrink-to-zero) + `copyWith`; generator sets 0.5 for L21–30; `BurstObject.visualScale` reads it; shapes never shrink below half on the top 2 worlds |
| **MH.3** | `[ ]` Tests updated + added | L1–20 keep original caps (≥ 1.1 s, 32–52 px, ≤ 9, ≤ 7); L21–30 assert eased caps + `minVisualScale` 0.0/0.5 split; `visualScale` floors at config value; suite green |
| **MH.4** | `[ ]` Star-threshold sanity | easier L21–30 ⇒ higher scores ⇒ confirm L29/L30 overrides keep 3-star a stretch; hand-override only, no curve change |
| **MH.5** | `[ ]` Bug-MS: score-50 centre pop | stray pop-in fires in screen centre when score crosses 50 (suspect milestone overlay / detached `ObjectPopIn`); trace trigger, then remove or make it a deliberate cue; regression-test it |
| **MH.6** | `[ ]` Device verify (dev-unlock) | L26–30 human-clearable (shapes readable to expiry, no firehose); L1–20 feel unchanged; no stray centre-pop at score 50 |

**Hotfix H gate → 5A:** MH.1–MH.6 `[x]`; `analyze` clean; full `test` green; device-verified at L30 +
L1 (still gentle) + score-50 (no stray pop). _(Guardrail recorded: **≤ 2 simultaneous modifiers** —
enforced in 5B/5H when modifiers land.)_

### Phase 5A — Practice Mode
| # | Milestone | Done-when |
|---|---|---|
| **M5A.1** | `[ ]` `practice` flag plumbed | map → intro → controller → GameOver (default `false`) |
| **M5A.2** | `[ ]` Long-press entry | long-press an unlocked node → that level in practice; normal tap = normal play |
| **M5A.3** | `[ ]` No-reward contract + copy | skips `saveStars` **and** `saveBestScore`; intro "PRACTICE RUN — NO SCORE SAVED"; GameOver labelled "PRACTICE" |
| **M5A.4** | `[ ]` Tests | practice leaves stars + best unchanged; non-practice still saves |
| **M5A.5** | `[ ]` Device verify | long-press → practice → finish → map stars & Start "BEST" unchanged |

**5A gate → 5B:** M5A.1–M5A.5 `[x]`; `analyze` clean; `test` green; device-verified.

### Phase 5B — Modifier framework + `blind` (+ coachmark)
| # | Milestone | Done-when |
|---|---|---|
| **M5B.1** | `[ ]` `RoundModifier` enum + `LevelConfig.modifiers` | `Set<RoundModifier>` (default `{}`) + `copyWith`; threaded to `DttGame` |
| **M5B.2** | `[ ]` `blind` hides AVOID | `HudOverlay` hides forbidden thumbnail when `blind` active |
| **M5B.3** | `[ ]` `blind` intro lengthen + copy | intro ~3.5s + "Memorize this! It will be hidden." |
| **M5B.4** | `[ ]` First-encounter coachmark | one-time per-modifier modal gated by `dtt_seen_modifier_<name>`; `blind` registers its blurb |
| **M5B.5** | `[ ]` Tests | HUD hides under `blind`; config carries set; intro duration switches; coachmark shows once |
| **M5B.6** | `[ ]` Device verify | blind: AVOID gone mid-round; coachmark first time only |

**5B gate → 5C:** M5B.1–M5B.6 `[x]`; `analyze` clean; `test` green; device-verified.

### Phase 5C — Endless Burst (pure survival, score-gated ramp)
| # | Milestone | Done-when |
|---|---|---|
| **M5C.1** | `[ ]` `GameMode.endless` path | no level number, **zero** modifiers |
| **M5C.2** | `[ ]` Survival-by-time economy | correct `+time`, mistakes `−time`, ends at 0; score accrues |
| **M5C.3** | `[ ]` Continuous ramp via score→`t` | `getEndlessConfig(score)` maps `t=(score/kEndlessRampScore).clamp(0,1)` → dial lerps, bypassing the level int |
| **M5C.4** | `[ ]` Best-score persistence + entry | `dtt_endless_best`; reachable from Start/Map |
| **M5C.5** | `[ ]` Tests | `getEndlessConfig` monotonic & clamps; time economy; best-of |
| **M5C.6** | `[ ]` Device verify | skill extends run; smooth ramp; ends at 0; best persists |

**5C gate → 5D:** M5C.1–M5C.6 `[x]`; `analyze` clean; `test` green; device-verified.

### Phase 5D — `dualTarget`
| # | Milestone | Done-when |
|---|---|---|
| **M5D.1** | `[ ]` Forbidden-set support | track a **set** of forbidden shapes; `isForbidden` iff `shape ∈ set`; bomb excluded |
| **M5D.2** | `[ ]` Intro shows both | forbidden-intro renders both shapes |
| **M5D.3** | `[ ]` Tests + combo smoke-test | iff-in-set across pool; two distinct forbidden; **`blind+dualTarget` flag-composition test** |
| **M5D.4** | `[ ]` Device verify | two AVOID shapes, both punished |

**5D gate → 5E:** M5D.1–M5D.4 `[x]`; `analyze` clean; `test` green; device-verified.

### Phase 5E — `ruleFlip` (inversion only)
| # | Milestone | Done-when |
|---|---|---|
| **M5E.1** | `[ ]` Inversion | cued window inverts tap-scoring; reverts cleanly |
| **M5E.2** | `[ ]` **Bomb immunity** | `if (obj.isBomb) { bomb penalty; return; }` **before** inversion — absolute No-Go |
| **M5E.3** | `[ ]` REVERSE cue (default) | bg `#111111`→`#1E3A8A` + center "REVERSE!" banner while inverted |
| **M5E.4** | `[ ]` **Reduce-flashing fallback (explicit)** | toggle ON → persistent `#1E3A8A` inset border + static "REVERSE" label, no bg flash; **dedicated test** |
| **M5E.5** | `[ ]` **No overlap with `blind`** | banner center/bg-led; never obscures the hidden AVOID slot |
| **M5E.6** | `[ ]` Tests | inverted only in window; bomb still penalised; reduce-flashing test asserts border+label, not bg animation |
| **M5E.7** | `[ ]` Device verify | obvious with & without reduce-flashing; bomb never a target |

**5E gate → 5F:** M5E.1–M5E.7 `[x]`; `analyze` clean; `test` green; device-verified.

### Phase 5F — `taskSwitch` (scheduled flipping)
| # | Milestone | Done-when |
|---|---|---|
| **M5F.1** | `[ ]` Scheduled flips | flips on a cadence reusing 5E inversion + cue; interval from config |
| **M5F.2** | `[ ]` Clean state at round end | no dangling inversion on `_endRound`/pause; bomb immunity holds |
| **M5F.3** | `[ ]` Tests | flips on schedule; each toggles inversion + cue; reverts by round end |
| **M5F.4** | `[ ]` Device verify | repeated flips legible, not a flicker storm |

**5F gate → 5G:** M5F.1–M5F.4 `[x]`; `analyze` clean; `test` green; device-verified.

### Phase 5G — `nBack` checkpoint variant
| # | Milestone | Done-when |
|---|---|---|
| **M5G.1** | `[ ]` **Wave-history queue** | `CheckpointManager` bounded `Queue<List<ShapeType>>`; push each wave; `len>3 → removeFirst()` (NFR-09) |
| **M5G.2** | `[ ]` `CheckpointSpec` carries n-back | flag selects n-back vs set/order; `N` configurable (default 2) |
| **M5G.3** | `[ ]` Overlay prompt | "Which shape was in the wave **N** ago?"; standard checkpoint economy (no extra live penalty) |
| **M5G.4** | `[ ]` Tests | correct == wave-N-ago shape; no phantoms; `+/-` time; queue bounded |
| **M5G.5** | `[ ]` Device verify | answerable paused; resume clean; fair under load |

**5G gate → 5H:** M5G.1–M5G.5 `[x]`; `analyze` clean; `test` green; device-verified.

### Phase 5H — Progression rewrite + surfacing + ship copy
| # | Milestone | Done-when |
|---|---|---|
| **M5H.1** | `[ ]` `getModifiersForLevel(int)` + re-tuned curve | returns the modifier set per the progression table; mechanics front-loaded; **speed eased on intro levels**; caps + override map kept |
| **M5H.2** | `[ ]` World themes updated | `_worlds` = Foundation / Cognitive Shift / Interference / Working Memory / Dual Load / Gauntlet |
| **M5H.3** | `[ ]` Affected tests reworked + green | `level_config_test`, `forbidden_change_test`, map tests; `getModifiersForLevel` asserted per level |
| **M5H.4** | `[ ]` Playtest W1–W3 | sawtooth holds; every modifier seen by ~L9; intro levels feel like breathers |
| **M5H.5** | `[ ]` Playtest W4–W6 | W5 combos read cleanly; W6 gauntlet hard but human-possible |
| **M5H.6** | `[ ]` Honesty copy pass | paradigm-based naming; **no "clinically proven"** claims |

**Ship gate:** M5H.1–M5H.6 `[x]`; `analyze` clean; full `test` green; campaign verified on device.

---

## Tracking rules
1. **One phase in flight at a time.** Don't open Phase N+1 milestones until Phase N's gate row is fully `[x]`.
2. **Every milestone is device-or-test verifiable** — if you can't state its Done-when as a pass/fail check, it isn't a milestone yet.
3. **Guardrails are not milestones to skip:** the 48px hitbox floor (M1.2), the mandatory flashing toggle shipping *with* the blast (M2.4) **and the REVERSE cue's non-flashing fallback (M5E.4)**, one-ScoreManager/one-forbidden-source (`dualTarget` widens it to a *declared set*), **the bomb as an absolute No-Go — immune to `ruleFlip` (M5E.2)**, **no hidden physics manipulation (data integrity — Phase 4A caps/clamps + rejected comeback assist; Practice Mode is the only assist and is star-disqualifying)**, and **generated difficulty stays hand-overridable** all survive every phase.
4. Update each `[ ]` → `[~]` → `[x]` as you go; the gate rows are the only thing that authorizes the next phase.
