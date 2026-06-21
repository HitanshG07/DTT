# Phase 2 — Bomb + White Blast + Time Economy: Progress & Handoff

> **Phase 2 CODE COMPLETE.** ✅ `flutter analyze` clean, `flutter test` **88/88 green**. All
> Phase-2 mechanics wired end to end (bomb, time economy, white blast, Reduce-flashing toggle +
> plumbing, Phase-2 tests). **Only remaining: device/emulator verification + commit.**
> Companions: `DTT_2.0_ROADMAP.md §5`, `DTT_2.0_MILESTONES.md` (M2.x), `PROJECT_PROGRESS.md`.

## Goal
Add the **Bomb** (second always-salient inhibition channel, never the forbidden shape),
convert lives→**time budget** (forbidden tap −2s, bomb tap −4s, both reset combo), add the
capped **WhiteBlastEffect**, and ship a **mandatory "Reduce flashing" toggle** with it.

---

## ✅ DONE so far
- `config/shape_type.dart` — added `ShapeType.bomb` (with doc: never forbidden, render salient).
- `shapes/bomb_shape.dart` — NEW. Self-colouring salient bomb (dark sphere + bright rim + red
  fuse-spark); ignores the passed paint colour so it never blends with off-white targets.
- `shapes/base_shape.dart` — `case ShapeType.bomb: return BombShape();` (+ import). This was
  the only exhaustive switch over ShapeType.
- `components/burst_object.dart` — added `onBombTap` callback (required ctor param), `isBomb`
  getter, and tap routing: `if (isBomb) onBombTap; else if (isForbidden) onWrongTap; else
  onCorrectTap`. (Bomb render needs no change — BombShape self-colours.)
- `config/level_config.dart` — added `bombChance` (default 0.0).
- `config/level_registry.dart` — bombChance per level: L1 0.0, L2 0.08, L3 0.12, L4 0.16, L5 0.20.
- `spawn_manager.dart` — `tickWave` injects bombs on non-forced slots when
  `bombChance > 0 && random.nextDouble() < bombChance` (the `> 0` guard means bomb-free
  configs consume no randomness → Phase-1 wave tests unaffected). Bombs always `isForbidden:false`.
- `config/game_constants.dart` — `kForbiddenTimePenalty = 2.0`, `kBombTimePenalty = 4.0`.
- `score_manager.dart` — added `onPenaltyTap()` (combo/streak/accuracy reset, **no life loss**);
  refactored `onWrongTap()` = `onPenaltyTap()` + `lives -= 1` (preserves 1.x/Zen behaviour).
- `effects/white_blast_effect.dart` — NEW. Single 150ms pulse, **opacity hard-capped at
  `kMaxOpacity = 0.75`**, no strobe; `reduced` flag → soft edge vignette (`kReducedMaxOpacity = 0.4`).

---

## ✅ ALSO DONE (the former blockers + full time economy)
- `dtt_game.dart`: `_createBurstObject` passes `onBombTap: _onBombTap`; `_reduceFlashing` field
  (reads `RealGameController.reduceFlashing`); import of `white_blast_effect`.
- `dtt_game.dart` time economy (M2.2b): `_onWrongTap` → `onPenaltyTap()` +
  `addTime(-kForbiddenTimePenalty)`, lives/`life_lost` removed, `isExpired→_endRound`. New
  `_onBombTap` → `onPenaltyTap()` + `addTime(-kBombTimePenalty)` + `WhiteBlastEffect(reduced:
  _reduceFlashing)` + shake + slow-mo + `isExpired→_endRound`. `_onExpired` now exempts bombs
  (`isForbidden || isBomb`). `_endRound` persists best score (fixes the Phase-1 timer-end gap).
- `real_game_controller.dart`: `final bool reduceFlashing` ctor param (default false).
- `test/game/burst_object_test.dart`: `onBombTap: (_) {}` added.
- **Verified: analyze clean, 81/81 tests pass.**

## ✅ ALSO DONE — Reduce-flashing toggle + tests (M2.4, M2.5)
- `real_game_controller.dart`: `reduceFlashing` field ✅.
- `screens/forbidden_intro_screen.dart`: passes `reduceFlashing: prefs.getBool('dtt_reduce_flashing')
  ?? false` into RealGameController ✅.
- `screens/settings_screen.dart`: third `SwitchListTile` "Reduce Flashing" wired to key
  `dtt_reduce_flashing` (saved immediately) ✅.
- `test/game/phase2_bomb_test.dart`: bomb fills non-guaranteed slots / never forbidden /
  forbidden-iff-shape invariant; `onPenaltyTap` resets combo with NO life loss; `onWrongTap`
  still deducts a life ✅.
- `test/game/white_blast_effect_test.dart`: opacity cap 0.75, reduced flag stored, single-pulse
  auto-remove ✅.

## ⛔ REMAINING (does NOT block build)
- **M2.6 device/emulator verification** (user): bombs appear & are always dangerous; forbidden
  tap −2s, bomb tap −4s (watch the countdown bar); timer-zero ends round & saves best; white
  blast is a single capped pulse; toggle ON → vignette instead of flash, and it persists.
- **Commit Phase 2** to a branch after device-verify.

## Known notes / deferred
- **HUD still shows 3 lives hearts** in burst even though lives never change now (time is the
  resource). Cosmetic inconsistency — defer hiding/replacing them (avoid hud_overlay_test churn);
  flag in ledger.
- Bomb tap reuses `wrong_tap.ogg`; a dedicated shatter SFX lands in Phase 5 audio pass.
- `reduceFlashing` is read once at game construction (fine; settings change applies next round).

## Fast resume
Clear blockers (1–2) → `flutter analyze` → finish 3–5 → `flutter test` (expect 81 + new) →
update ledger. Engine entry points: `dtt_game.dart` (`_onWrongTap`, new `_onBombTap`,
`_onExpired`, `_endRound`), `components/burst_object.dart`, `effects/white_blast_effect.dart`.
