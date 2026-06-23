// ═══════════════════════════════════════════════════════════════
// dtt_game.dart — THE live FlameGame for Don't Tap That.
// This is the only Flame world file. dont_tap_game.dart was a
// Stage 0 stub and has been deleted. Do NOT create any other
// FlameGame file. All Stage 6+ changes go here.
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show TextStyle;

import 'components/burst_object.dart';
import 'components/tap_feedback_effect.dart';
import 'config/game_constants.dart';
import 'config/game_mode.dart';
import 'config/level_config.dart';
import 'config/shape_type.dart';
import 'shapes/base_shape.dart';
import 'game_controller.dart';
import 'object_pool.dart';
import 'score_manager.dart';
import 'spawn_manager.dart';
import 'timer_manager.dart';
import 'checkpoint_manager.dart';
import 'config/checkpoint_spec.dart';
import 'managers/forbidden_manager.dart';
import 'real_game_controller.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../services/score_service.dart';
import 'effects/score_pop.dart';
import 'effects/screen_flash.dart';
import 'effects/screen_shake.dart';
import 'effects/ring_burst.dart';
import 'effects/milestone_overlay_effect.dart';
import 'effects/slow_motion_effect.dart';
import 'effects/forbidden_change_warning.dart';
import 'effects/white_blast_effect.dart';
import 'effects/frenzy_edge_effect.dart';

/// The main Flame game engine for Don't Tap That.
///
/// Wires together [SpawnManager], [ScoreManager], [ObjectPool], and
/// [FallingObject] components. Uses [TapCallbacks] so tap
/// events route automatically to individual [FallingObject.onTapDown].
///
/// Reference: Section 8, Section 2.5, Section 2.6.
class DttGame extends FlameGame {
  /// The game controller providing state and lifecycle management.
  final GameController controller;

  /// Level configuration for the current round.
  final LevelConfig levelConfig;

  /// Colour for correct (non-forbidden) shapes. Passed from GameScreen
  /// to keep lib/game/ free of Flutter widget imports (Section 7.2).
  final Color correctColor;

  /// Colour for the forbidden shape.
  final Color forbiddenColor;

  /// Fill colour for shapes. Identical for forbidden and correct objects so
  /// colour never reveals the forbidden shape (Section 2.5).
  final Color shapeColor;

  /// Active gameplay engine. Phase 1 ships [GameMode.burst]; [GameMode.zen]
  /// (the preserved falling engine) is surfaced in Phase 5.
  /// Reference: DTT_2.0_ROADMAP.md §2.1.
  final GameMode gameMode;

  late SpawnManager _spawnManager;
  late ScoreManager _scoreManager;
  late TimerManager _timerManager;
  late CheckpointManager _checkpointManager;
  late ObjectPool<BurstObject> _pool;
  late ShapeType _currentForbidden;

  /// The recall challenge currently being presented, or null. Read by the
  /// GameScreen to populate the [MemoryCheckpointOverlay] (2.0 Phase 3, §6).
  CheckpointPrompt? _activeCheckpoint;
  CheckpointPrompt? get activeCheckpoint => _activeCheckpoint;

  /// Checkpoints resolved / aced this round (Feature M) — surfaced to the
  /// controller so Game Over can show the Memory rating.
  int get checkpointsShown => _checkpointManager.checkpointsShown;
  int get checkpointsPerfect => _checkpointManager.checkpointsPerfect;

  /// Active Frenzy-window overlay (Feature M), tracked so [_endRound] can remove
  /// it and stop a gold edge bleeding into Game Over.
  FrenzyEdgeEffect? _frenzyEffect;

  /// Gold tint for ScorePop while Frenzy Mode is active (matches the cue).
  static const Color _frenzyGold = Color(0xFFF5B301);

  double _forbiddenChangeTimer = 0.0;
  bool _roundEnded = false;
  int _changeCount = 0;

  /// TimeScale lives on DttGame for wrong-tap slow-motion (FR-09, Section 6.4)
  double timeScale = 1.0;

  /// "Reduce flashing" accessibility setting (2.0 §5): downgrades the bomb
  /// White Blast to an edge vignette. Read once from the controller.
  late final bool _reduceFlashing = (controller is RealGameController)
      ? (controller as RealGameController).reduceFlashing
      : false;

  /// Forbidden change warning active states (Section 4.6)
  bool _forbiddenWarningActive = false;
  double _forbiddenWarningTimer = 0.0;

  bool _forbiddenChangeInProgress = false;
  bool _forbiddenChangePending = false;
  Timer? _forbiddenTimerCallback;

  /// Best score at the start of the round to check for personal best beat (Section 6.2)
  int _bestAtStart = 0;

  /// Score milestones for audio/visual feedback (Section 2.3).
  static const List<int> _milestones = [50, 100, 200, 350, 500];
  int _lastMilestoneIndex = -1;

  DttGame({
    required this.controller,
    required this.levelConfig,
    required this.correctColor,
    required this.forbiddenColor,
    required this.shapeColor,
    this.gameMode = GameMode.burst,
  }) {
    if (controller is RealGameController) {
      (controller as RealGameController).game = this;
    }
  }

  /// Expose AudioService via the controller
  AudioService? get _audio => (controller is RealGameController)
      ? (controller as RealGameController).audioService
      : null;

  /// Expose HapticsService via the controller
  HapticsService? get _haptics => (controller is RealGameController)
      ? (controller as RealGameController).hapticsService
      : null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fetch personal best at start of round
    final scoreService = ScoreService();
    _bestAtStart = await scoreService.getBestScore();

    // 1. Use the forbidden shape the Forbidden Intro already selected so the
    //    cue the player memorised matches the in-game forbidden (Section 2.5).
    //    Fall back to a fresh pick only if none was set (e.g. mock/test paths).
    _currentForbidden =
        controller.state.forbiddenShape.value ?? _pickInitialForbidden();
    controller.state.forbiddenShape.value = _currentForbidden;

    // 2. Initialise object pool (Section 9).
    _pool = ObjectPool<BurstObject>(
      poolSize: GameConstants.kMaxPoolSize,
      createObject: (index) => _createBurstObject(),
    );

    // 3. Initialise spawn manager (Section 2.1, FR-18, FR-19, FR-20).
    _spawnManager = SpawnManager(
      config: levelConfig,
      forbiddenShape: _currentForbidden,
      random: Random(),
    );

    // 4. Use the controller's single ScoreManager so taps, accuracy, and
    //    longest streak share one source of truth read by the Game Over
    //    screen (Section 2.8). Only create a local one for non-Real
    //    controllers (mock/test paths).
    _scoreManager = (controller is RealGameController)
        ? (controller as RealGameController).scoreManager
        : ScoreManager(controller.state);

    // 5. Round countdown timer (2.0 Burst, §4). Seeds GameState.timeRemaining
    //    to the full round duration so the HUD shows a full bar immediately.
    _timerManager = TimerManager(
      state: controller.state,
      roundDuration: levelConfig.roundDuration,
    );

    // 5b. Memory checkpoint manager (2.0 Phase 3, §6). Disabled levels make it
    //     a no-op (assignToken/isDue always false).
    _checkpointManager = CheckpointManager(
      spec: levelConfig.checkpoint,
      random: Random(),
    );

    // 6. Round start audio cue (Section 6.2)
    _audio?.play('round_start.ogg');

    // 7. Reset forbidden change timer and count.
    _forbiddenChangeTimer = 0.0;
    _changeCount = 0;
  }

  @override
  void update(double dt) {
    if (_roundEnded) return;

    final bool warningWasActive = _forbiddenWarningActive;
    if (_forbiddenWarningActive) {
      _forbiddenWarningTimer -= dt;
      timeScale = 0.0; // Freeze object movement during warning pause
      if (_forbiddenWarningTimer <= 0) {
        _endForbiddenChangeSequence();
      }
    }

    // 1. Forbidden change timer (Levels 4-5).
    // Timer runs from round start (after warmup ends, not from app launch).
    // The change sequence must NOT trigger on the Pause overlay (handled because Flame's paused is true stops update).
    if (levelConfig.forbiddenChanges && !_spawnManager.isInWarmup && !paused) {
      final isLevel4 = levelConfig.forbiddenInterval == 30;
      if (!isLevel4 || _changeCount < 1) {
        _forbiddenChangeTimer += dt;
        if (_forbiddenChangeTimer >= levelConfig.forbiddenInterval) {
          _rotateForbiddenShape();
          _changeCount++;
          _forbiddenChangeTimer = 0.0;
        }
      }
    }

    // If warning was active, update children/effects but skip other gameplay logic
    if (warningWasActive) {
      super.update(dt);
      return;
    }

    super.update(dt);

    // 2. Score manager tick (idle decay).
    _scoreManager.tick(dt);

    // 3. Round timer (2.0 Burst, §4). The time-economy clock runs from round
    //    start — it must NOT sit frozen during the spawn warmup, which read as
    //    "the timer started too late". It is frozen only while a checkpoint
    //    modal is open (also enforced by paused) and during a forbidden-change
    //    warning (the early return above).
    if (!controller.state.checkpointActive.value) {
      _timerManager.tick(dt);
      if (_timerManager.isExpired) {
        _endRound();
        return;
      }
    }

    // 3b. Memory checkpoints (§6) only after the warmup ease-in — no recall
    //     prompts during the opening window; frozen while a modal is open.
    if (!_spawnManager.isInWarmup && !controller.state.checkpointActive.value) {
      _checkpointManager.tick(dt);
      if (_checkpointManager.isDue) {
        _openCheckpoint();
        return;
      }
    }

    // 4. Spawn logic -- emit a wave and scatter each object in 2D.
    _spawnManager.updateActiveCount(_pool.activeCount);
    final wave = _spawnManager.tickWave(dt);
    if (wave.isNotEmpty) {
      _spawnWave(wave);
    }
  }

  /// Spawns a wave of [BurstObject]s, scattering each at a non-overlapping 2D
  /// position inside the play area (below the HUD bar). Capped by
  /// [LevelConfig.maxObjects] and the pool size. Reference: §4 (Phase 1).
  void _spawnWave(List<SpawnDecision> wave) {
    const double top = GameConstants.kBurstPlayAreaTopInset;
    final double areaHeight =
        size.y - top - GameConstants.kBurstPlayAreaBottomInset;

    // Active positions (mounted from earlier frames) for overlap avoidance.
    final active = children.whereType<BurstObject>().toList();
    final existingX = <double>[for (final o in active) o.position.x];
    final existingY = <double>[for (final o in active) o.position.y];

    // At most one special token-carrying target per wave (§6), spread over time.
    bool tokenAssigned = false;

    for (final decision in wave) {
      if (_pool.activeCount >= levelConfig.maxObjects) break;
      final obj = _pool.acquire();
      if (obj == null) break;

      final (x, y) = _spawnManager.generate2DPosition(
        existingX,
        existingY,
        size.x,
        areaHeight,
        areaTop: top,
      );
      // Track within-wave so later objects in the same wave avoid this one.
      existingX.add(x);
      existingY.add(y);

      // The token rides a normal target (not a bomb / forbidden) so "specials"
      // are things the player is meant to tap and remember. assignToken is only
      // called for an eligible slot, so a recorded token is always rendered.
      String? objToken;
      if (!_spawnManager.isInWarmup &&
          !tokenAssigned &&
          !decision.isForbidden &&
          decision.shapeType != ShapeType.bomb) {
        objToken = _checkpointManager.assignToken();
        if (objToken != null) tokenAssigned = true;
      }

      obj.reconfigure(
        newShapeType: decision.shapeType,
        newIsForbidden: decision.isForbidden,
        newPosition: Vector2(x, y),
        newLifetime: levelConfig.objectLifetime,
        newToken: objToken,
      );

      if (!obj.isMounted) {
        add(obj);
      }
    }
  }

  /// Explicit Shader Warmup Gate rendering (Reviewer Addition 2)
  /// Forces GPU shader compilation of all painters and effects during the 12s warmup.
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_roundEnded && _spawnManager.isInWarmup) {
      canvas.save();
      final Paint warmupPaint = Paint()
        // ignore: deprecated_member_use
        ..color = const Color(0x00FFFFFF) // 0 opacity
        ..style = PaintingStyle.fill;

      // Force render all 7 shapes
      for (final type in ShapeType.values) {
        final painter = BaseShape.forType(type);
        painter.paintShape(canvas, const Size(1, 1), warmupPaint);
      }

      // Force render ScorePop text shader path
      final textPaint = TextPaint(
        style: const TextStyle(
          fontSize: 1,
          color: Color(0x00000000), // 0 opacity
        ),
      );
      textPaint.render(canvas, "warmup", Vector2.zero());

      canvas.restore();
    }
  }

  /// Picks the initial forbidden shape uniformly at random from the
  /// level's shape pool. Reference: Section 2.5.
  ShapeType _pickInitialForbidden() {
    final shapes = levelConfig.shapes;
    return shapes[Random().nextInt(shapes.length)];
  }

  @override
  set paused(bool value) {
    final wasPaused = super.paused;
    super.paused = value;
    if (wasPaused != value) {
      if (value) {
        _forbiddenTimerCallback?.cancel();
        _forbiddenTimerCallback = null;
      } else {
        resume();
      }
    }
  }

  void resume() {
    if (_forbiddenChangePending) {
      _forbiddenChangePending = false;
      _rotateForbiddenShape();
      return;
    }

    if (_forbiddenChangeInProgress && _forbiddenWarningActive && _forbiddenWarningTimer > 0) {
      _forbiddenTimerCallback?.cancel();
      _forbiddenTimerCallback = Timer(
        Duration(milliseconds: (_forbiddenWarningTimer * 1000).round()),
        () {
          _endForbiddenChangeSequence();
        },
      );
    }
  }

  void _endForbiddenChangeSequence() {
    if (_forbiddenChangeInProgress) {
      timeScale = 1.0;
      _forbiddenChangeInProgress = false;
      _forbiddenWarningActive = false;
      _forbiddenWarningTimer = 0.0;
      _forbiddenTimerCallback?.cancel();
      _forbiddenTimerCallback = null;
    }
  }

  /// Rotates the forbidden shape to a new random shape from the pool,
  /// excluding the current one (no-repeat rule, Section 2.5).
  /// Reference: FR-13, Section 2.6.
  void _rotateForbiddenShape() {
    if (_forbiddenChangeInProgress) {
      // Debug-only (no print() in release — Architectural Rules 7.2), matching
      // the spawn-overlap fallbacks.
      assert(() {
        // ignore: avoid_print
        print("Warning: Forbidden change sequence already in progress. Dropping trigger.");
        return true;
      }());
      return;
    }

    if (paused) {
      _forbiddenChangePending = true;
      return;
    }

    _forbiddenChangeInProgress = true;
    timeScale = 0.0;

    _currentForbidden = ForbiddenManager.selectForbidden(
      config: levelConfig,
      previousForbidden: _currentForbidden,
    );
    controller.state.forbiddenShape.value = _currentForbidden;
    _spawnManager.forbiddenShape = _currentForbidden;

    // Play forbidden change audio (Section 6.2)
    _audio?.play('forbiddenchange.ogg');

    // Fire haptic: HapticFeedback.mediumImpact (via HapticsService)
    _haptics?.mediumImpact();

    // Trigger gameplay warning pause (Section 4.6)
    _forbiddenWarningActive = true;
    _forbiddenWarningTimer = 1.5;
    add(ForbiddenChangeWarningEffect(newShape: _currentForbidden));

    _forbiddenTimerCallback?.cancel();
    _forbiddenTimerCallback = Timer(const Duration(milliseconds: 1500), () {
      _endForbiddenChangeSequence();
    });
  }

  /// Creates a new [BurstObject] for the pool. The object's shape, position,
  /// and lifetime are set later via [BurstObject.reconfigure].
  BurstObject _createBurstObject() {
    final obj = BurstObject(
      shapeType: ShapeType.circle,
      isForbidden: false,
      levelConfig: levelConfig,
      shapeColor: shapeColor,
      onCorrectTap: _onCorrectTap,
      onWrongTap: _onWrongTap,
      onBombTap: _onBombTap,
      onExpired: _onExpired,
    );
    // Pool release happens ONLY after Flame has fully removed the
    // component from the tree, preventing ghost-loop re-acquisition.
    obj.onRemoved = () => _pool.release(obj);
    return obj;
  }

  /// Handles a correct tap on a non-forbidden object.
  void _onCorrectTap(BurstObject obj) {
    final int prevScore = controller.state.score.value;
    final int prevMultiplier = _scoreManager.multiplier;

    // The awarded points already include the combo and the Frenzy ×2 (Feature M),
    // so the ScorePop shows the real number ("+20"/"+40") instead of a hardcoded +10.
    final int awarded = _scoreManager.onCorrectTap();
    final bool frenzy = _scoreManager.isFrenzyActive;

    // Pitch ladder calculation: raised by 4 semitones per combo step (Section 6.2)
    final double pitch = _audio?.pitchLadderEnabled == true
        ? pow(2, ((_scoreManager.multiplier - 1) * 4) / 12.0).toDouble()
        : 1.0;
    _audio?.play('correct_tap.ogg', pitch: pitch);
    _haptics?.correct();

    // ScorePop floating "+points" (Section 6.4); gold while Frenzy is active.
    add(ScorePop(
      text: "+$awarded",
      position: obj.position.clone(),
      color: frenzy ? _frenzyGold : correctColor,
    ));

    // RingBurst expanding white circle (Section 6.4)
    add(RingBurst(
      position: obj.position.clone(),
      size: levelConfig.objectSize.toDouble(),
    ));

    // Check milestone crossing (Section 2.3, FR-10)
    final int newScore = controller.state.score.value;
    for (int i = 0; i < _milestones.length; i++) {
      if (prevScore < _milestones[i] && newScore >= _milestones[i] && i > _lastMilestoneIndex) {
        _lastMilestoneIndex = i;
        _triggerMilestone(_milestones[i]);
        break;
      }
    }

    // Check combo up audio cue (Section 4.5)
    if (_scoreManager.multiplier > prevMultiplier) {
      _audio?.play('combo_up.ogg');
    }

    // Check proximity warning (FR-15)
    final forbiddenObjects = children.whereType<BurstObject>().where((o) => o.isForbidden);
    for (final forbidden in forbiddenObjects) {
      if (ForbiddenManager.isWithinProximity(obj.position, forbidden.position)) {
        controller.state.proximityTrigger.value++;
        break;
      }
    }

    // Spawn tap feedback effect at object position.
    add(TapFeedbackEffect(
      position: obj.position.clone(),
      color: correctColor,
      size: levelConfig.objectSize.toDouble(),
    ));
  }

  /// Trigger milestone-specific overlay and audio/haptics (Section 2.3)
  void _triggerMilestone(int milestoneValue) {
    String message = "";
    switch (milestoneValue) {
      case 50:
        message = "Nice Start!";
        // No centre ring here: a RingBurst at screen-centre looks identical to a
        // correct-tap pop (added at the tapped object in _onCorrectTap) but with
        // no object under it, so it reads as a phantom tap. The slide-in banner
        // below is the milestone cue, consistent with the other milestones.
        break;
      case 100:
        message = "Sharp Focus!";
        break;
      case 200:
        message = "On Fire!";
        break;
      case 350:
        message = "Elite Control!";
        // full-screen flash on milestone
        add(ScreenFlash(color: correctColor));
        break;
      case 500:
        message = "Untouchable!";
        break;
    }
    if (message.isNotEmpty) {
      add(MilestoneOverlayEffect(message: message));
      _audio?.play('milestone.ogg');
      _haptics?.milestone();
    }
  }

  /// Handles a wrong tap on the forbidden object (2.0 time economy, §5).
  ///
  /// Burst mode costs **time, not lives**: tapping the forbidden shape resets
  /// the combo (no life loss) and subtracts [GameConstants.kForbiddenTimePenalty]
  /// from the round clock. If that drains the clock the round ends.
  void _onWrongTap(BurstObject obj) {
    if (_roundEnded) return;
    final int prevMultiplier = _scoreManager.multiplier;

    // wrongtap.ogg fires immediately on the tap event (Reviewer Addition 1)
    _audio?.play('wrong_tap.ogg');
    _haptics?.wrong();

    // INTEGRITY (Feature M): forbidden penalty + combo-reset are frenzy-agnostic —
    // the sprint never softens inhibition.
    _scoreManager.onPenaltyTap();
    _timerManager.addTime(-GameConstants.kForbiddenTimePenalty);

    // Red screen flash + shake + slow motion.
    add(ScreenFlash(color: forbiddenColor));
    add(ScreenShake());
    add(SlowMotionEffect());

    // Check combo break.
    if (_scoreManager.multiplier < prevMultiplier) {
      _audio?.play('combo_break.ogg');
    }

    // Penalty may have drained the clock -> end the round.
    if (_timerManager.isExpired) {
      _endRound();
    }

    // Spawn tap feedback effect in error colour.
    add(TapFeedbackEffect(
      position: obj.position.clone(),
      color: forbiddenColor,
      size: levelConfig.objectSize.toDouble(),
    ));
  }

  /// Handles a tap on a bomb (always-salient hazard, §5).
  ///
  /// Costs more time than the forbidden shape
  /// ([GameConstants.kBombTimePenalty]), resets the combo, and fires the capped
  /// [WhiteBlastEffect] (downgraded to an edge vignette when "Reduce flashing"
  /// is on). Bombs are never the forbidden shape, so there is no combo-break
  /// audio distinction here.
  void _onBombTap(BurstObject obj) {
    if (_roundEnded) return;

    // No dedicated bomb SFX asset yet (Phase 5 audio pass); reuse wrong_tap.
    _audio?.play('wrong_tap.ogg');
    _haptics?.wrong();

    // INTEGRITY (Feature M): the bomb keeps its full penalty and combo-reset even
    // during Frenzy Mode — the double-points sprint is a deliberate temptation
    // trap, so "tap wildly" must still punish a bomb. Penalty is frenzy-agnostic.
    _scoreManager.onPenaltyTap();
    _timerManager.addTime(-GameConstants.kBombTimePenalty);

    // Capped, single-pulse white blast (seizure-safe; edge vignette if reduced).
    add(WhiteBlastEffect(reduced: _reduceFlashing));
    add(ScreenShake());
    add(SlowMotionEffect());

    if (_timerManager.isExpired) {
      _endRound();
    }

    add(TapFeedbackEffect(
      position: obj.position.clone(),
      color: forbiddenColor,
      size: levelConfig.objectSize.toDouble(),
    ));
  }

  /// Opens a memory checkpoint (§6): freezes the round and signals the
  /// GameScreen (via [GameState.checkpointActive]) to show the recall modal.
  void _openCheckpoint() {
    _activeCheckpoint = _checkpointManager.buildPrompt();
    controller.state.checkpointActive.value = true;
    paused = true;
  }

  /// Resolves the open checkpoint with the player's [selected] tokens: applies
  /// the time reward/penalty, clears the prompt, and resumes the round. Called
  /// by the GameScreen when the modal is submitted. Reference: §6.
  void resolveCheckpoint(List<String> selected) {
    if (_activeCheckpoint == null) return;
    final CheckpointOutcome outcome = _checkpointManager.resolve(selected);
    _timerManager.addTime(outcome.timeDelta);
    _activeCheckpoint = null;
    controller.state.checkpointActive.value = false;
    paused = false;

    // Acing the checkpoint ignites Frenzy Mode (Feature M): a 5 s double-points
    // sprint with an unmistakable gold edge cue (steady when reduce-flashing).
    if (outcome.perfect) {
      _scoreManager.startFrenzy();
      _frenzyEffect?.removeFromParent();
      _frenzyEffect = FrenzyEdgeEffect(reduced: _reduceFlashing);
      add(_frenzyEffect!);
      _audio?.play('frenzytick.ogg');
      _haptics?.milestone();
    }

    if (_timerManager.isExpired) {
      _endRound();
    }
  }

  /// Handles a burst object whose lifetime expired before it was tapped.
  void _onExpired(BurstObject obj) {
    // An expired correct object drops the combo multiplier one step; an expired
    // forbidden object OR bomb is exempt -- letting a forbidden/bomb expire is
    // the correct (no-tap) behaviour (FR-06, Section 2.3). No audio, no penalty.
    _scoreManager.onMissed(obj.isForbidden || obj.isBomb);
  }

  /// Ends the current round.
  ///
  /// Plays game_over or new_best audio depending on result.
  void _endRound() {
    _roundEnded = true;

    // Kill any in-flight Frenzy so a sprint started near 0:00 can't leave a gold
    // edge ticking on the Game Over screen (Feature M). update() early-returns
    // once _roundEnded, so the effect must be removed explicitly here.
    _scoreManager.endFrenzy();
    _frenzyEffect?.removeFromParent();
    _frenzyEffect = null;

    final score = controller.state.score.value;
    // Persist best score on the timer-end path too. In Burst mode lives never
    // reach 0, so LifeManager's save never fires; without this a timed-out
    // round would not record a new best. saveBestScore is idempotent.
    ScoreService().saveBestScore(score);
    if (score > _bestAtStart && _bestAtStart > 0) {
      _audio?.play('new_best.ogg');
    } else {
      _audio?.play('game_over.ogg');
    }
  }

  @override
  void onRemove() {
    _forbiddenTimerCallback?.cancel();
    _forbiddenTimerCallback = null;
    _forbiddenChangeInProgress = false;
    _forbiddenChangePending = false;
    timeScale = 1.0;

    _scoreManager.dispose();
    super.onRemove();
  }
}