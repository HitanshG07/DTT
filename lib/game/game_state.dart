import 'package:flutter/foundation.dart';

import 'config/game_constants.dart';
import 'config/shape_type.dart';

/// Observable game state exposed as ValueNotifiers.
///
/// Stage 2 UI binds to these notifiers. Both MockGameController and
/// RealGameController (Stage 4) drive the same notifier instances.
///
/// Reference: Section 10.1 -- GameState contract.
class GameState {
  /// Current accumulated score. Initial: 0.
  final ValueNotifier<int> score = ValueNotifier<int>(0);

  /// Remaining lives. Initial: kLives (3). Reference: FR-05.
  final ValueNotifier<int> lives = ValueNotifier<int>(GameConstants.kLives);

  /// Current combo multiplier (x1--x5). Initial: 1. Reference: Section 2.3.
  final ValueNotifier<int> multiplier = ValueNotifier<int>(1);

  /// Combo decay arc progress. 1.0 = full, 0.0 = empty.
  /// Drains over kIdleDecaySeconds (4 s). Resets on correct tap.
  /// Reference: FR-16, Section 4.4.
  final ValueNotifier<double> decayProgress = ValueNotifier<double>(1.0);

  /// Currently forbidden shape, or null if none is active yet.
  /// Reference: Section 2.5.
  final ValueNotifier<ShapeType?> forbiddenShape =
      ValueNotifier<ShapeType?>(null);

  /// Trigger for proximity warnings (FR-15).
  final ValueNotifier<int> proximityTrigger = ValueNotifier<int>(0);

  /// Seconds remaining in the current round (2.0 Burst mode countdown).
  /// Initial: 0.0 until [TimerManager] seeds it on round start. Unused by the
  /// 1.x falling / Zen path, which is lives-based.
  /// Reference: DTT_2.0_ROADMAP.md §2.2, §4 (Phase 1).
  final ValueNotifier<double> timeRemaining = ValueNotifier<double>(0.0);

  /// Whether a memory-checkpoint recall modal is open (2.0 Phase 3, §6). While
  /// true the round timer is frozen and gameplay is paused.
  final ValueNotifier<bool> checkpointActive = ValueNotifier<bool>(false);

  /// Disposes all ValueNotifiers to prevent memory leaks.
  ///
  /// **WARNING:** GameScreen must call gameState.dispose() in its widget
  /// dispose() lifecycle method, BEFORE Navigator.pop() completes.
  /// Because this module is entered and exited repeatedly within a
  /// single parent-app session, undisposed notifiers accumulate on
  /// the heap. Ten enter/exit cycles without disposal can silently
  /// consume the 80 MB budget defined in NFR-09. Verify during
  /// Phase 7: enter and exit the module 10 times in one session and
  /// confirm heap returns to baseline each time in Flutter DevTools
  /// Memory view.
  /// Guards against double-disposal. The [GameController] contract already
  /// disposes state (see GameController.dispose), so a caller that also disposes
  /// it directly would otherwise trigger "A ValueNotifier was used after being
  /// disposed". Disposal is therefore idempotent.
  bool _disposed = false;

  /// Reference: Section 7.2 -- ValueNotifier Disposal.
  ///
  /// Idempotent: safe to call more than once (subsequent calls are no-ops).
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    score.dispose();
    lives.dispose();
    multiplier.dispose();
    decayProgress.dispose();
    forbiddenShape.dispose();
    proximityTrigger.dispose();
    timeRemaining.dispose();
    checkpointActive.dispose();
  }
}
