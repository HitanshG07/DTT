import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import 'components/falling_object.dart';
import 'components/tap_feedback_effect.dart';
import 'config/game_constants.dart';
import 'config/level_config.dart';
import 'config/shape_type.dart';
import 'game_controller.dart';
import 'object_pool.dart';
import 'score_manager.dart';
import 'spawn_manager.dart';

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

  /// Score milestones for audio/visual feedback (Section 2.3).
  static const List<int> _milestones = [50, 100, 200, 350, 500];
  int _lastMilestoneIndex = -1;

  DttGame({
    required this.controller,
    required this.levelConfig,
    required this.correctColor,
    required this.forbiddenColor,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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

    // 5. Round start audio cue.
    // MOCK: AudioService.play('round_start.ogg') -- wired in Stage 5.

    // 6. Shader warmup: during the warmup window the first spawned
    //    objects will exercise all shape painters, warming the GPU
    //    shader pipeline. No additional code needed beyond ensuring
    //    diverse shapes spawn during warmup (Section 2.6 / NFR-05).

    // 7. Reset forbidden change timer.
    _forbiddenChangeTimer = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_roundEnded) return;

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

        // STAGE 5: apply slowMotion speedMultiplier to all active objects

        if (!obj.isMounted) {
          add(obj);
        }
      }
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

    // MOCK: AudioService.play('forbidden_change.ogg') -- wired in Stage 5.
  }

  /// Creates a new [FallingObject] for the pool. The object's shape
  /// and position are set later via [FallingObject.reconfigure].
  FallingObject _createFallingObject() {
    return FallingObject(
      shapeType: ShapeType.circle,
      isForbidden: false,
      levelConfig: levelConfig,
      correctColor: correctColor,
      forbiddenColor: forbiddenColor,
      onCorrectTap: _onCorrectTap,
      onWrongTap: _onWrongTap,
      onMissed: _onMissed,
    );
  }

  /// Handles a correct tap on a non-forbidden object.
  void _onCorrectTap(FallingObject obj) {
    final int prevScore = controller.state.score.value;
    final int prevMultiplier = _scoreManager.multiplier;

    _scoreManager.onCorrectTap();
    _pool.release(obj);

    // MOCK: AudioService.play('correct_tap.ogg') -- wired in Stage 5.

    // Check milestone crossing.
    final int newScore = controller.state.score.value;
    for (int i = 0; i < _milestones.length; i++) {
      if (prevScore < _milestones[i] && newScore >= _milestones[i] && i > _lastMilestoneIndex) {
        _lastMilestoneIndex = i;
        // MOCK: AudioService.play('milestone.ogg') -- wired in Stage 5.
        break;
      }
    }

    // Check combo up.
    if (_scoreManager.multiplier > prevMultiplier) {
      // MOCK: AudioService.play('combo_up.ogg') -- wired in Stage 5.
    }

    // Spawn tap feedback effect at object position.
    add(TapFeedbackEffect(
      position: obj.position.clone(),
      color: correctColor,
      size: levelConfig.objectSize.toDouble(),
    ));
  }

  /// Handles a wrong tap on the forbidden object.
  void _onWrongTap(FallingObject obj) {
    final int prevMultiplier = _scoreManager.multiplier;

    _scoreManager.onWrongTap();
    _pool.release(obj);

    // MOCK: AudioService.play('wrong_tap.ogg') -- wired in Stage 5.
    // MOCK: AudioService.play('life_lost.ogg') -- wired in Stage 5.

    // Check combo break.
    if (_scoreManager.multiplier < prevMultiplier) {
      // MOCK: AudioService.play('combo_break.ogg') -- wired in Stage 5.
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
    _pool.release(obj);
    // No audio. No life change. Reference: Section 2.1.
  }

  /// Ends the current round.
  ///
  /// Pauses all spawning. Plays game_over audio. Does NOT call
  /// controller.quit() -- the screen handles navigation via the
  /// lives ValueNotifier listener already wired in game_screen.dart.
  void _endRound() {
    _roundEnded = true;
    // MOCK: AudioService.play('game_over.ogg') -- wired in Stage 5.
  }
}