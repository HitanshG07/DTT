# Phase 3 — Memory Checkpoints: Progress & Handoff

> **Phase 3 CODE COMPLETE.** ✅ `flutter analyze` clean, `flutter test` **95/95 green** (was 88
> → +7 checkpoint tests). All Phase-3 mechanics wired end to end. **Only remaining:
> device/emulator verification + commit.**
> Companions: `DTT_2.0_ROADMAP.md §6`, `DTT_2.0_MILESTONES.md` (M3.x), `PROJECT_PROGRESS.md`.

## Goal
Add a working-memory-span layer: some targets carry tokens; periodically a recall checkpoint
**pauses the round timer** and asks the player to recall what they saw (+5s correct / −3s wrong).

## Files
**New:**
- `config/checkpoint_spec.dart` — `CheckpointSpec` (enabled, interval, specialsPerWindow,
  recallCount, orderMatters, distractorCount, tokens, reward/penalty) + `CheckpointPrompt`.
- `game/checkpoint_manager.dart` — pure-Dart logic: `assignToken`, `tick`/`isDue`,
  `buildPrompt`, `resolve` (set- & order-recall grading), `reset`.
- `overlays/memory_checkpoint_overlay.dart` — Flutter recall modal.
- `test/game/checkpoint_manager_test.dart` — 7 tests.

**Modified:**
- `config/level_config.dart` — `checkpoint` field (default disabled) + `copyWith`.
- `config/level_registry.dart` — L3/L4 set-recall, L5 order-recall; L1–L2 off.
- `components/burst_object.dart` — `token` field, centred glyph render, `reconfigure(newToken)`.
- `game/game_state.dart` — `checkpointActive` notifier (+ disposed).
- `game/dtt_game.dart` — `CheckpointManager` wired; timer + checkpoint clock gated on
  `checkpointActive`; one special token per wave (rides a normal target; recorded only when
  rendered); `_openCheckpoint` (pause + active); public `resolveCheckpoint(selected)`.
- `screens/game_screen.dart` — listens to `checkpointActive`, shows the modal, calls
  `resolveCheckpoint`.
- `test/game/forbidden_change_test.dart` — builds games with checkpoints disabled (via
  `copyWith`) so the headless rotation tests aren't blocked by a checkpoint pause.

## Design notes
- **Token rides a normal target** (never bomb/forbidden) so "specials" are things you tap and
  remember. `assignToken` is only called for an eligible slot, so a recorded token is always
  actually shown (no quizzing on an unseen token).
- **Checkpoint freezes everything:** `paused=true` halts the Flame loop; `checkpointActive` also
  gates the timer/checkpoint clock for safety + unit-testability.
- **Order vs set recall:** L5 requires the exact order; L3/L4 membership only.

## ⛔ REMAINING — device verification (M3.6), then commit
Play Level 3+ and confirm: special targets visibly carry token glyphs; at the interval a recall
modal opens and the **countdown bar freezes**; correct recall adds time, wrong subtracts; the
round resumes cleanly after submit. Then commit Phase 3.

## Known cosmetic (deferred, unchanged from Phase 2)
HUD still shows 3 lives hearts though lives never change in burst mode.
