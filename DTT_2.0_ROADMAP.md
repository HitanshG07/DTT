# Don't Tap That 2.0 — Spatial Burst Roadmap

> **Status:** Phases 0–4 complete & green (`analyze` clean, 111/111 tests; 4C device-verified).
> Phase 5 **replanned 2026-06-22** (Modes, Modifiers & Accelerated Progression — see §8) and
> documented; implementation not yet started.
> **Source of truth:** `Dont_Tap_That_2.0_Master_Plan.docx` (§ references below point to it).
> **This document:** the goal, the per-phase work, the files touched, the data-model
> changes, the tests, and the acceptance gate for each phase. Each phase is multi-day and
> gets its own focused implementation plan when started — this is the master roadmap they
> hang off.

---

## 1. The goal

Turn DTT from a **falling-object score-chase** into a **timed visual-search + inhibition +
working-memory** game, without throwing away the verified engine we already have.

| | Today (1.x, falling) | 2.0 (Spatial Burst) |
|---|---|---|
| Object motion | Falls top → bottom | Static; appears at a 2D spot, **shrinks in place** as its lifetime drains |
| "Miss" | Fell off the bottom | Lifetime expired (shrank to nothing) |
| Spawning | One object per interval | A **wave of 4–6** objects per interval, scattered in 2D |
| Round end | Lives reach 0 | **Time budget** reaches 0 (lives removed in Phase 2) |
| Inhibition channels | Forbidden shape only | Forbidden shape (memory) **+** Bomb (always-salient) — two distinct channels, never merged |
| Memory load | Remember 1 forbidden shape | Forbidden shape **+** periodic recall checkpoints |
| Progression | Linear levels | **30-level chaptered winding-path map** (6 worlds × 5), difficulty from a generated sawtooth curve, 3-star mastery |

### Design guardrails (do not violate)
- **One `ScoreManager`, one source of truth for the forbidden shape.** These were the
  Phase-0 bugs; 2.0 reuses the exact managers and must not regress them.
- **Pure-Dart managers stay Flame-free** (`ScoreManager`, `SpawnManager`, new
  `TimerManager`) — planning §7.2. UI binds to `GameState` `ValueNotifier`s only.
- **Tap hitbox never shrinks below 48 px** (NFR-07), even when the *visual* shrinks.
- **Seizure safety is mandatory, not optional** — the White Blast (Phase 2) is capped,
  non-strobe, and ships with a "Reduce flashing" toggle in the same PR that adds it.
- **Marketing honesty (§1):** lean on paradigms ("go/no-go inhibition, visual search,
  working-memory span"). **Never** claim "clinically proven brain training" (the
  Lumosity / FTC trap). Carry into store copy at ship.
- **Config-driven difficulty (§3.3):** difficulty lives entirely in `LevelConfig`. From
  Phase 4 the 30 levels are **generated from a curve** (not hand-typed), but the principle
  holds — the engine consumes a `LevelConfig`, **zero logic changes** per level.
- **NO hidden physics manipulation — EVER (data integrity).** This is a cognitive-training
  module: difficulty is only ever what the `LevelConfig` declares. We must **never** secretly
  alter physics/time (e.g. a silent "comeback assist" that lengthens object lifetime after
  failures) — doing so corrupts the user's processing-speed/accuracy signal and destroys
  scientific credibility. Any assistance is **explicit and star-disqualifying** (a labelled
  Practice Mode, or a visual hint), never covert.
- **Generated difficulty must be hand-overridable.** The `LevelGenerator` produces a baseline,
  but a mandatory `Map<int, …>` override map lets any level whose formula plays badly be
  hand-tuned (esp. late "Gauntlet" star thresholds, where realistic human scores fall well
  below the theoretical max). The override map is not optional.

---

## 2. Architecture decisions that span all phases

### 2.1 Fork, don't mutate — `GameMode { burst, zen }`
`FallingObject` and the falling spawn path are the **verified, fully-tested Phase-0
engine**. So we **forked** rather than rewrote in place:
- Add a top-level `GameMode` enum.
- `DttGame` branches on it: `burst` uses `BurstObject` + wave/2D spawning + timer;
  `zen` uses the existing `FallingObject` + falling spawn untouched.
- Phases 1–4 build and ship `burst` as the active mode. `zen` stays dormant but intact.

**Why:** protects the 7 verified fixes and avoids a risky big-bang rewrite. **Note (Phase 5
replan, 2026-06-22):** Phase 5 no longer surfaces `zen` — reviving the old falling engine as a
"Zen" mode was dropped as low-value. `zen` remains a dormant, tested code path; the new
**Endless Burst** mode (new engine) replaces its replayability role and **Practice Mode** serves
the limited-assist intent. See §8.

### 2.2 The `GameState` contract grows additively
Every phase only **adds** `ValueNotifier`s to `GameState` (and disposes them). Existing
notifiers (`score`, `lives`, `multiplier`, `decayProgress`, `forbiddenShape`,
`proximityTrigger`) keep working so both modes drive the same contract.

| Notifier | Added in | Purpose |
|---|---|---|
| `timeRemaining : double` | Phase 1 | Round countdown for HUD |
| `checkpointActive : bool` | Phase 3 | Pauses timer while recall modal is open |
| (Bomb/blast are component + effect state, not notifiers) | Phase 2 | — |

### 2.3 Reused infrastructure (confirmed present in repo)
Object pool, shape painters (`BaseShape.forType`), `AudioService` / `HapticsService`,
`ScoreService` (best-score persistence), Mock/Real controller split, and the `SpawnScript`
tutorial hook all already exist and are reused. Doc §12's mapping is accurate.

---

## 3. Phase 0 — Baseline (DONE, verify before Phase 1)

The bug-fix work that 2.0's §13 "Prerequisites" depend on. **Already implemented and
verified live; not yet committed to git.**

- One `ScoreManager` shared by `DttGame` and `RealGameController` (C1).
- Intro-selected forbidden == in-game forbidden (C4).
- Combo resets on wrong tap; missed correct object drops combo one step (C2/C3).
- Identical off-white shape color (color never reveals danger).
- `DttGame` constructed once (not in `build()`), HUD overflow fixed (72px), debug-only
  spawn warning.
- Regression tests: stats wiring, forbidden-iff-shape invariant, HUD no-overflow.

**Gate into Phase 1:** commit Phase 0 to a branch → `flutter analyze` clean →
`flutter test` green. *(Three deferred cosmetic items live in `VISUAL_TODO.md`; not
blocking.)*

---

## 4. Phase 1 — Engine pivot: Spatial Burst

**Goal:** replace falling with a static, shrinking-lifetime burst loop; spawn 4–6 object
waves in 2D; introduce a round countdown timer. Lives still end the round (time economy is
Phase 2). The big structural change. Doc §2, §4, §12.

### Build
1. **`lib/game/components/burst_object.dart` (new, forked from `FallingObject`):**
   - Remove vertical motion. `update`: `_remaining -= dt * timeScale`; visual scale =
     `_remaining / _lifetime`; at `_remaining <= 0` fire `onExpired(this)` once (reuse the
     `_hasBeenHandled` guard) and remove.
   - **Hitbox fixed** at `max(objectSize, 48)` while the painter shrinks (NFR-07).
   - Keep off-white `shapeColor`, audio debounce, double-fire guard. `reconfigure` now
     takes 2D `newPosition` + `newLifetime`.
2. **`lib/game/spawn_manager.dart` → wave + 2D:**
   - `List<SpawnDecision> tickWave(double dt)` emits `config.waveSize` decisions per
     interval. Preserve warmup cap, forbidden-guarantee, and the
     **`isForbidden` iff `shapeType == forbiddenShape`** invariant.
   - `generateX` → `generate2DPosition(List<Vector2> existing, Rect playArea)`: same
     overlap logic, distance-based in 2D, inside the play rect (below the 72px HUD).
     Keep the ≤3-attempt + fallback pattern.
   - `SpawnScript` mode emits single-item waves (tutorial unaffected).
3. **`lib/game/game_state.dart`:** add `timeRemaining : ValueNotifier<double>` (+ dispose).
4. **`lib/game/timer_manager.dart` (new, pure Dart):** counts `roundDuration` down, writes
   `state.timeRemaining`, exposes `isExpired`. Round ends on **lives==0 OR timer==0**
   (natural end → save via existing rule).
5. **`lib/game/dtt_game.dart`:** add `GameMode`; burst branch uses `BurstObject` pool,
   `tickWave`, `generate2DPosition`, `TimerManager.tick`. `_onExpired` maps to the **same**
   `_scoreManager.onMissed(isForbidden)` (correct-expiry drops combo, forbidden exempt — no
   scoring-logic change). All effects carry over.
6. **`lib/game/config/level_config.dart` + `level_registry.dart`:** add `waveSize` (def 5),
   `objectLifetime` (~2.5s), `roundDuration` (~60s) with safe defaults; one tuned value per
   level, no logic change to falling fields.
7. **HUD:** add a countdown readout (thin top progress bar bound to `timeRemaining`).

### Data model
- `GameMode { burst, zen }`; `GameState.timeRemaining`; `LevelConfig.{waveSize,
  objectLifetime, roundDuration}`; `SpawnDecision` now carries a 2D position.

### Tests
- `burst_object_test.dart`: lifetime decrements; visual scale tracks `remaining/lifetime`;
  `onExpired` fires exactly once; **hitbox stays ≥48 while shrinking**.
- `spawn_manager_test.dart` (extend): wave = 4–6; 2D positions respect overlap radius;
  forbidden-iff-shape holds across the wave.
- `timer_manager_test.dart`: counts down, writes `timeRemaining`, ends at 0.
- `object_pool_test.dart` (extend): 2D `reconfigure` releases cleanly.
- Full suite incl. all Phase-0 regression tests stays green.

### Acceptance gate
Waves of off-white shapes appear scattered, shrink, and vanish; tapping correct scores;
letting a correct one expire drops the combo; the timer counts down and ends the round at 0;
forbidden cue still matches the intro. `analyze` clean, `test` green, verified on emulator.

### Out of scope (later)
Bomb, White Blast, lives→time penalties, checkpoints, map, Zen UI, audio assets.

---

## 5. Phase 2 — Bomb + White Blast + time economy

**Goal:** add a second inhibition channel (Bomb), convert lives into a time budget, and add
the capped White Blast with mandatory accessibility. Doc §3, §5, §11.

### Build
1. **`ShapeType.bomb`:** always-salient black bomb; **never** becomes the forbidden shape
   and never rotates. Two distinct inhibition channels (forbidden = memory, bomb =
   always-avoid) — **do not merge them.** Add a bomb painter (`BaseShape`), and exclude
   bomb from forbidden selection/rotation (`ForbiddenManager`, `SpawnManager`).
2. **Time economy (lives dropped):** route penalties through time, not lives —
   - correct tap → +score / +combo (unchanged scoring);
   - forbidden tap → **−2s** + reset multiplier to x1;
   - bomb tap → **−4s** + reset multiplier;
   - correct-target expiry → −1 combo step (already wired in Phase 1).
   Natural end = `timeRemaining` hits 0 → save (reuses §2.7 / FR-12). Remove the
   lives loss condition; keep `GameState.lives` field only if Zen mode still needs it
   (Zen stays lives-based), otherwise gate it by mode.
3. **`lib/game/effects/white_blast_effect.dart` (new):** a single ~150 ms pulse, **capped
   ≤75% opacity, no strobe / no repeat**, with heavy haptic + shatter sound. Triggered on
   bomb tap.
4. **Mandatory "Reduce flashing" accessibility toggle** (Settings + persisted): when on,
   White Blast downgrades to a static edge-vignette (no full-screen flash). This ships in
   the **same** PR as the blast — seizure safety is not a follow-up.
5. Reuse existing ScorePop / RingBurst / ScreenShake / SlowMotion for the rest.

### Data model
- `ShapeType.bomb`; settings flag `reduceFlashing : bool` (persisted, e.g. via the existing
  settings/prefs path); time-penalty constants in `GameConstants` /`LevelConfig`
  (`bombChance`, `forbiddenTimePenalty`, `bombTimePenalty`).

### Tests
- Bomb is never selected as forbidden and never rotates in.
- Tapping forbidden subtracts 2s; tapping bomb subtracts 4s + resets combo; both via
  `timeRemaining`, not lives.
- White Blast respects the opacity cap and fires once (no strobe loop).
- `reduceFlashing` on → blast path uses the vignette branch (assert no full-screen flash
  component is added).

### Acceptance gate
Bombs appear and are always dangerous regardless of the forbidden shape; mis-taps cost
time; timer-zero ends the round and saves; the flash is a single capped pulse; the
accessibility toggle visibly changes blast behavior and persists across launches.

### Out of scope
Checkpoints, map, 3-star, Zen UI.

---

## 6. Phase 3 — Memory checkpoints

**Goal:** add a working-memory-span layer: some targets carry tokens you must recall.
Doc §6.

### Build
1. **Special targets:** a few targets per window are marked `special` and carry a token
   (number / letter / animal). Token rendered on the `BurstObject` (small glyph) and
   recorded as "seen" when it appears.
2. **`lib/overlays/memory_checkpoint_overlay.dart` (new) Flutter modal:** opens at a
   checkpoint; **timer paused** (`GameState.checkpointActive = true` → `TimerManager` halts
   and `DttGame.paused`-style freeze). Positive recall task: "tap the 3 animals you saw"
   (set recall); at higher levels **order recall**. Correct → **+5s**, wrong → **−3s**.
3. **`GameState.checkpointActive : ValueNotifier<bool>`** drives the pause + modal.
4. Checkpoint cadence comes from `LevelConfig` (see Phase 4 config fields).

### Data model
- `GameState.checkpointActive`; `BurstObject.token` (nullable); a `CheckpointSpec` in
  `LevelConfig` (how many specials, recall type, reward/penalty).

### Tests
- `checkpointActive` true → `TimerManager` does not decrement.
- Correct recall adds 5s; wrong subtracts 3s.
- Tokens shown during a window are exactly the set offered for recall (no phantom options).
- Order-recall variant validates sequence, not just membership.

### Acceptance gate
Specials visibly carry tokens; reaching a checkpoint freezes the timer and opens the modal;
recall outcome adjusts time; resuming continues the round cleanly.

### Out of scope
Map, 3-star, Zen UI.

---

## 7. Phase 4 — Progression: 30-level generated map + 3-star mastery

**Goal:** scale from 5 hand-tuned levels to **30 generated levels** on a chaptered
winding-path map, with config-driven 3-star mastery. Big enough to split into three gated
sub-phases (4A logic → 4B stars → 4C map/UI). Doc §8, §9.

### Design — how 30 levels are distributed
- **6 worlds × 5 levels = 30**, each world introducing one mechanic then ramping it:
  W1 Warm-up · W2 Hazards · W3 Memory · W4 Shifting Rules · W5 Mastery · W6 Nightmare.
- **Mechanic breakpoints:** bombs @L4 · memory checkpoints @L9 · forbidden rotation @L13 ·
  order-recall @L21. (Players master a mechanic before the next arrives.)
- **Sawtooth difficulty curve, not a ramp:** each world starts with a small "breather" then
  climbs past the previous world's peak (flow channel). Within a world:
  L1 breather → L2–L3 build → L4 hard → **L5 "Gauntlet" challenge** (combined peak).
- **Flavors** (per-level emphasis so levels feel distinct and each *hard* level pushes ONE
  cognitive system, not all): Calm, Swarm (search+speed), Minefield (inhibition),
  Recall (memory), Shuffle (set-shifting), Gauntlet (combined; world bosses only).
- **Human-possible hard caps (never crossed by the generator):** recall ≤3 tokens (4 only at
  L26+); object lifetime ≥1.1s; hitbox ≥48px; bomb chance ≤30%; forbidden-rotation interval
  ≥12s; ~6–8% difficulty step per level. "Hard" = combining *fair* demands under time
  pressure, never an inhuman wall. **Refined by Hotfix H (2026-06-22):** the top 2 worlds
  (L21–30) get *stricter* humane floors — lifetime ≥1.7s, size 42–52px, ≥50% visual-shrink floor,
  ≤7 on-screen, waves ≤6, spawn ≤1.4/s — after L30 tested as humanly impossible; L1–20 unchanged.

### Phase 4A — Difficulty engine (pure logic, no UI)
- `StarThresholds` (3 cutoffs, `starsFor(score)`); `LevelConfig.starThresholds`.
- **`LevelGenerator` (pure Dart):** worlds + sawtooth + per-dial interpolation + flavor
  modifiers + human-limit clamps + **mandatory override `Map<int, …>`** (baseline generated,
  any level hand-tunable — esp. late star thresholds).
- Rewire `LevelRegistry.forLevel` → generator; **30 levels**.
- *Ripple (handled honestly):* L1–L5 exact numbers change, so `level_config_test` is rewritten
  to assert **curve invariants** (size strictly decreases, no bombs <L4, rotation only ≥L13,
  exactly 30 levels, caps respected); `forbidden_change_test` becomes **config-driven** (it
  builds a rotating config via `copyWith`, since rotation now starts at L13 not L4).
- **Gate:** generator tests green (curve, breakpoints, caps, overrides); no regressions.

### Phase 4B — Stars & progression (logic + small UI)
- Star evaluation at round end (final score → stars via thresholds).
- **Per-level best-star persistence** (extend `ScoreService`/sibling, best-of semantics) +
  **unlock gating** (Level N unlocks at **≥1★** on N−1; no energy/attempt limits).
- Game Over screen shows stars earned.
- **Gate:** threshold→stars, unlock-gating, persist-across-launch tests green; device-verify.

### Phase 4C — The map + navigation (UI) — split into two safe parts

**Phase 4C-1 — Map screen (render + data binding, no flow changes)**
- **`lib/screens/map_screen.dart`:** chaptered winding path, **30 nodes in 6 world segments**
  (banners, per-world tint), scroll + auto-scroll to current, locked/unlocked nodes, stars per
  node — all read from `ProgressService` (`getAllStars` / `isUnlocked`).
- Reachable via a route, but the **existing nav flow is untouched** (node taps are a no-op or
  log only). Low-risk, self-contained, widget-testable.
- **Gate:** map renders all 30 nodes with correct locks/stars from persisted progress; scrolls;
  no regression to existing flow.

**Phase 4C-2 — Navigation flow (wire it in)**
- Flow: `Start → Map → tap node → forbidden-intro(level) → game → Game Over (stars) → back to
  Map`. Threads the chosen `level` through route args → `RealGameController(level:)`.
- Node taps launch the selected level; Game Over returns to the Map (not just retry/home).
- **Gate:** picking a node plays that level; clearing it awards/saves stars and unlocks the
  next; stars survive restart; device-verified.

### Out of scope
Zen mode UI, Practice Mode, final polish (all Phase 5).

---

## 8. Phase 5 — Modes, Modifiers & Accelerated Progression

> **Replanned (2026-06-22).** The original Phase 5 ("revive the falling engine as a Zen mode +
> chores") was dropped as low-value. Phase 5 now finishes the game around its **identity** — a
> go/no-go inhibition + visual-search + working-memory trainer. The relaxation / limited-assist
> intent the old Zen carried is served instead by **Practice Mode on the new engine**. The
> dormant `GameMode.zen` stays dormant and is **not** surfaced.

**Goal:** add two real modes + a composable cognitive-modifier system, and re-tune the 30-level
curve so the depth is felt early (not buried at L20–30).

### Decisions (locked in review)
- **Modifiers are CAMPAIGN-FLAVOR ONLY** — a `Set<RoundModifier>` baked into levels; **no**
  player-selectable toggles/menus (no menu bloat, no invalid combos, curated curve guaranteed).
- **Endless = pure survival, NO modifiers** — a raw processing-speed test.
- **Accelerated "tasting menu"** — every modifier introduced by ~L9.

### The two modes
- **Practice Mode** — replay any level with the **real, unaltered physics** but **no stars and no
  best-score saved** (the sanctioned, star-disqualifying grind tool; honours the
  no-hidden-assist guardrail). Entry: **long-press a map node**.
- **Endless Burst** — survival on the burst engine with **no modifiers**; difficulty ramps
  **continuously by score** (`LevelGenerator.getEndlessConfig(score)` → existing dial lerps,
  bypassing the level integer). Survival-by-time (correct +time, mistakes −time, ends at 0).
  Separate `dtt_endless_best` key.

### The modifier system (one engine, a few flags)
Five "modes" people imagine are really one core loop with twists, so they ship as a composable
`Set<RoundModifier>` on `LevelConfig` — not separate screens:

| Modifier | Paradigm | Changes | Hook |
|---|---|---|---|
| `blind` | working memory | hide the AVOID reminder after the intro | `HudOverlay` |
| `dualTarget` | dual-task | two forbidden shapes | `ForbiddenManager`/`SpawnManager` |
| `ruleFlip` | response inhibition | invert the rule for a cued window | tap-scoring in `DttGame` |
| `taskSwitch` | set-shifting | flip the rule on a cadence | scheduled `ruleFlip` |
| `nBack` | working-memory span | "shape seen N waves ago" | checkpoint + bounded wave-history queue |

### Accelerated progression (re-tunes the `LevelGenerator`)
Speed is **dialed back on each modifier's introduction level** (a mechanical breather while
learning) so the sawtooth flow holds.

| World | Levels | Theme | Mechanics / modifiers |
|---|---|---|---|
| 1 | 1–5 | The Foundation | L1–3 pure burst · L4 bombs · L5 set-recall checkpoints |
| 2 | 6–10 | The Cognitive Shift | L6 `blind` · L7 `dualTarget` · L8 `ruleFlip` · L9 `nBack` · L10 mix (slow/easy) |
| 3 | 11–15 | Interference | faster; heavy `taskSwitch` + high bombs |
| 4 | 16–20 | Working Memory | heavy `blind` + `nBack`; moderate speed |
| 5 | 21–25 | Dual Load | combos: L21 `blind+dualTarget` · L24 `ruleFlip+nBack` |
| 6 | 26–30 | The Gauntlet | all dials maxed; rapidly alternating modifiers |

### Critical design rulings (from review)
- **Bomb is immune to `ruleFlip`** — always an absolute No-Go; checked **before** any inversion,
  or we'd train players to rapid-tap the highest-threat object.
- **REVERSE cue has a concrete reduce-flashing fallback** — when the toggle is on, a persistent
  `#1E3A8A` inset border + a **static** "REVERSE" label replace the animated bg-shift (no strobe).
- **`nBack` uses the standard checkpoint economy** (no extra live-time penalty) and needs a
  bounded `Queue<List<ShapeType>>` wave history in `CheckpointManager` (NFR-09 memory budget).
- **First-encounter coachmark** — a one-time per-modifier modal so a new mechanic never reads as
  a bug, gated by a `dtt_seen_modifier_<name>` pref.

### Sub-phases (each gated: `analyze` clean + `test` green + device check)
`5.0 docs` → `Part A dev-unlock` → `Hotfix H humane caps` → `5A Practice` → `5B framework+blind` →
`5C Endless` → `5D dualTarget` → `5E ruleFlip` → `5F taskSwitch` → `5G nBack` →
`5H progression rewrite + ship copy`.
Full milestone tables: `DTT_2.0_MILESTONES.md` (Phase 5) and the implementation plan.

**Hotfix H — humane difficulty caps (L21–30 only).** Dev-unlock playtesting of L30 showed the late
campaign was *humanly impossible* (objects too fast/small to identify, shrinking to a dot). Fix:
raise the human-possible floors on **worlds 5 & 6 only** (L1–20 untouched) so difficulty comes from
**cognitive load**, not sub-human perception/motor demands — lifetime ≥ 1.7 s, size 42–52 px, a
≥ 50 % visual-shrink floor (data-driven via `LevelConfig.minVisualScale`), ≤ 7 on-screen, waves ≤ 6,
spawn ≤ 1.4/s. Also recorded: **≤ 2 simultaneous modifiers** ever (cap-the-chaos guardrail, enforced
in 5B/5H), and **Bug-MS** (a stray centre "pop" when score crosses 50).

### Out of scope (parked as future ideas)
Feedback/feel features (mistake replay, tap heatmap, stop-signal, focus-sprint), Calibration,
Calm mode, Daily challenge, custom round builder, seed codes, cosmetics, full tutorial. Audio
assets + `VISUAL_TODO.md` cosmetics + store-copy honesty still ride along (copy pass in 5H).

---

## 9. Build sequence & dependencies

```
Phase 0 (commit) ─> Phase 1 (engine) ─> Phase 2 (bomb/time) ─> Phase 3 (memory)
                                                                     │
        ┌────────────────────────────────────────────────────────────┘
        v
   Phase 4A (difficulty engine: generator, 30 levels, curve+flavors+caps+overrides)
        │
        v
   Phase 4B (stars: evaluation, per-level persistence, unlock gating)
        │
        v
   Phase 4C (map UI: chaptered winding path + navigation)
        │
        v
   Phase 5 (Practice + Endless Burst + Modifier system + accelerated 30-level progression)
```

- **Hard gate between every phase:** prior phase on a physical/emulator device, `analyze`
  clean, full `test` green. Do not start a phase until the one before it passes.
- Each phase gets its **own detailed implementation plan** (this doc is the master); that
  plan enumerates exact diffs and the test list before any code.
- **Effort:** Phase 0 ≈ done. Phases 1–5 ≈ multi-week total, ~days each.

## 10. Cross-cutting concerns (track across all phases)
- **Accessibility:** 48px hitbox floor (P1); Reduce-flashing toggle (P2); color-independent
  shape identity (already true).
- **Audio:** `assets/audio/` currently has only `test.ogg`; all real SFX are silently dead.
  Needs real sound files (cannot be code-generated) — resolved in Phase 5, tracked from now.
- **Persistence:** best score (exists) → + per-level stars (P4) → + settings flags (P2).
- **Marketing honesty (§1):** applied at Phase 5 store copy; keep language paradigm-based.
