// ═══════════════════════════════════════════════════════════════
// dtt_game.dart — THE live FlameGame for Don't Tap That.
// This is the only Flame world file. dont_tap_game.dart was a
// Stage 0 stub and has been deleted. Do NOT create any other
// FlameGame file. All Stage 6+ changes go here.
// ═══════════════════════════════════════════════════════════════

import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show TextStyle;

import 'components/falling_object.dart';
import 'components/tap_feedback_effect.dart';
import 'config/game_constants.dart';
import 'config/level_config.dart';
import 'config/shape_type.dart';
import 'shapes/base_shape.dart';
import 'game_controller.dart';
import 'object_pool.dart';
import 'score_manager.dart';
import 'spawn_manager.dart';
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

  late SpawnManager _spawnManager;
  late ScoreManager _scoreManager;
  late ObjectPool _pool;
  late ShapeType _currentForbidden;

  double _forbiddenChangeTimer = 0.0;
  bool _roundEnded = false;

  /// TimeScale lives on DttGame for wrong-tap slow-motion (FR-09, Section 6.4)
  double timeScale = 1.0;

  /// Forbidden change warning active states (Section 4.6)
  bool _forbiddenWarningActive = false;
  double _forbiddenWarningTimer = 0.0;

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

    // 1. Pick initial forbidden shape.
    _currentForbidden = _pickInitialForbidden();
    controller.state.forbiddenShape.value = _currentForbidden;

    // 2. Initialise object pool (Section 9).
    _pool = ObjectPool(
      poolSize: GameConstants.kMaxPoolSize,
      createObject: (index) => _createFallingObject(),
    );

    // 3. Initialise spawn manager (Section 2.1, FR-18, FR-19, FR-20).
    _spawnManager = SpawnManager(
      config: levelConfig,
      forbiddenShape: _currentForbidden,
      random: Random(),
    );

    // 4. Initialise score manager (Section 2.2, 2.3, 2.4).
    _scoreManager = ScoreManager(controller.state);

    // 5. Round start audio cue (Section 6.2)
    _audio?.play('round_start.ogg');

    // 6. Reset forbidden change timer.
    _forbiddenChangeTimer = 0.0;
  }

  @override
  void update(double dt) {
    if (_roundEnded) return;

    // Handle mid-round forbidden change pause warning (Section 4.6)
    if (_forbiddenWarningActive) {
      _forbiddenWarningTimer -= dt;
      timeScale = 0.0; // Freeze object movement during warning pause
      if (_forbiddenWarningTimer <= 0) {
        _forbiddenWarningActive = false;
        timeScale = 1.0;
      }
      // Update children (like the warning effect text/timers) but skip gameplay logic
      super.update(dt);
      return;
    }

    super.update(dt);

    // 1. Score manager tick (idle decay).
    _scoreManager.tick(dt);

    // 2. Forbidden change timer (Levels 4-5).
    if (levelConfig.forbiddenChanges) {
      _forbiddenChangeTimer += dt;
      if (_forbiddenChangeTimer >= levelConfig.forbiddenInterval) {
        _rotateForbiddenShape();
        _forbiddenChangeTimer = 0.0;
      }
    }

    // 3. Spawn logic.
    _spawnManager.updateActiveCount(_pool.activeCount);
    final decision = _spawnManager.tick(dt);

    if (decision.shouldSpawn && _pool.activeCount < levelConfig.maxObjects) {
      final obj = _pool.acquire();
      if (obj != null) {
        final double xPos = _spawnManager.generateX(
          _pool.activeXPositions,
          size.x,
        );

        obj.reconfigure(
          newShapeType: decision.shapeType,
          newIsForbidden: decision.isForbidden,
          newPosition: Vector2(xPos, -levelConfig.objectSize.toDouble()),
          newSpeedMultiplier: 1.0,
        );

        if (!obj.isMounted) {
          add(obj);
        }
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

  /// Rotates the forbidden shape to a new random shape from the pool,
  /// excluding the current one (no-repeat rule, Section 2.5).
  /// Reference: FR-13, Section 2.6.
  void _rotateForbiddenShape() {
    final candidates =
        levelConfig.shapes.where((s) => s != _currentForbidden).toList();
    if (candidates.isEmpty) return;

    _currentForbidden = candidates[Random().nextInt(candidates.length)];
    controller.state.forbiddenShape.value = _currentForbidden;
    _spawnManager.forbiddenShape = _currentForbidden;

    // Play forbidden change audio (Section 6.2)
    _audio?.play('forbidden_change.ogg');

    // Trigger gameplay warning pause (Section 4.6)
    _forbiddenWarningActive = true;
    _forbiddenWarningTimer = 1.5;
    add(ForbiddenChangeWarningEffect(newShape: _currentForbidden));
  }

  /// Creates a new [FallingObject] for the pool. The object's shape
  /// and position are set later via [FallingObject.reconfigure].
  FallingObject _createFallingObject() {
    final obj = FallingObject(
      shapeType: ShapeType.circle,
      isForbidden: false,
      levelConfig: levelConfig,
      correctColor: correctColor,
      forbiddenColor: forbiddenColor,
      onCorrectTap: _onCorrectTap,
      onWrongTap: _onWrongTap,
      onMissed: _onMissed,
    );
    // Pool release happens ONLY after Flame has fully removed the
    // component from the tree, preventing ghost-loop re-acquisition.
    obj.onRemoved = () => _pool.release(obj);
    return obj;
  }

  /// Handles a correct tap on a non-forbidden object.
  void _onCorrectTap(FallingObject obj) {
    final int prevScore = controller.state.score.value;
    final int prevMultiplier = _scoreManager.multiplier;

    _scoreManager.onCorrectTap();

    // Pitch ladder calculation: raised by 4 semitones per combo step (Section 6.2)
    final double pitch = _audio?.pitchLadderEnabled == true
        ? pow(2, ((_scoreManager.multiplier - 1) * 4) / 12.0).toDouble()
        : 1.0;
    _audio?.play('correct_tap.ogg', pitch: pitch);
    _haptics?.correct();

    // ScorePop floating +10*Multiplier (Section 6.4)
    add(ScorePop(
      text: "+${10 * _scoreManager.multiplier}",
      position: obj.position.clone(),
      color: correctColor,
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
    final forbiddenObjects = children.whereType<FallingObject>().where((o) => o.isForbidden);
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
        // subtle ring burst in the center of the screen
        add(RingBurst(position: size / 2, size: 80.0));
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

  /// Handles a wrong tap on the forbidden object.
  void _onWrongTap(FallingObject obj) {
    if (_roundEnded) return;
    final int prevMultiplier = _scoreManager.multiplier;
    final int prevLives = controller.state.lives.value;

    // wrongtap.ogg fires immediately on the tap event (Reviewer Addition 1)
    _audio?.play('wrong_tap.ogg');
    _haptics?.wrong();

    _scoreManager.onWrongTap();

    final int newLives = controller.state.lives.value;
    if (newLives < prevLives) {
      // lifelost.ogg fires when LifeManager/lives updates confirm life deduction (Reviewer Addition 1)
      _audio?.play('life_lost.ogg');
      _haptics?.lifeLost();
    }

    // Red screen flash
    add(ScreenFlash(color: forbiddenColor));

    // Screen shake
    add(ScreenShake());

    // Slow motion effect
    add(SlowMotionEffect());

    // Check combo break.
    if (_scoreManager.multiplier < prevMultiplier) {
      _audio?.play('combo_break.ogg');
    }

    // Check game over.
    if (controller.state.lives.value <= 0) {
      _endRound();
    }

    // Spawn tap feedback effect in error colour.
    add(TapFeedbackEffect(
      position: obj.position.clone(),
      color: forbiddenColor,
      size: levelConfig.objectSize.toDouble(),
    ));
  }

  /// Handles an object that fell off the screen without being tapped.
  void _onMissed(FallingObject obj) {
    _scoreManager.onMissed();
    // No audio. No life change. Reference: Section 2.1.
  }

  /// Ends the current round.
  ///
  /// Plays game_over or new_best audio depending on result.
  void _endRound() {
    _roundEnded = true;
    final score = controller.state.score.value;
    if (score > _bestAtStart && _bestAtStart > 0) {
      _audio?.play('new_best.ogg');
    } else {
      _audio?.play('game_over.ogg');
    }
  }

  @override
  void onRemove() {
    _scoreManager.dispose();
    super.onRemove();
  }
}