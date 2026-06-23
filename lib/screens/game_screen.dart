import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../game/dtt_game.dart';
import '../game/game_controller.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/memory_checkpoint_overlay.dart';
import '../overlays/pause_overlay.dart';

/// Game Screen (S-06) representing the active gameplay layout.
///
/// Reference: Section 4.4, Section 5.1 S-06, Section 5.2, Section 7.2.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController _controller;
  // Built exactly once (see didChangeDependencies). MUST NOT be constructed in
  // build(): build() re-runs on every setState (pause/resume), and recreating
  // the game would reset the pool, re-roll the forbidden shape, and reset the
  // ScoreManager counters mid-round.
  late final DttGame _game;
  bool _isPaused = false;
  bool _hasInitialised = false;
  bool _navigatingToGameOver = false;
  // True once the round timer has been seeded (>0), so the initial 0.0 value of
  // timeRemaining isn't mistaken for "time up". 2.0 Burst mode (§4).
  bool _timerStarted = false;
  // Mirrors GameState.checkpointActive to show/hide the recall modal (§6).
  bool _checkpointActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialised) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map) {
        _controller = args['controller'] as GameController;
      } else {
        _controller = args as GameController;
      }
      _hasInitialised = true;

      // Build the Flame game ONCE here, not in build(), so pause/resume
      // (which call setState) never recreate it.
      _game = DttGame(
        controller: _controller,
        levelConfig: _controller.levelConfig,
        correctColor: AppColors.kCorrect,
        forbiddenColor: AppColors.kWrong,
        shapeColor: AppColors.kPrimaryText,
      );

      // Add listener to lives to navigate to Game Over when lives reach 0 (Section 5.2)
      _controller.state.lives.addListener(_checkGameOver);
      // Burst mode also ends the round when the countdown timer hits 0 (§4).
      _controller.state.timeRemaining.addListener(_checkTimeUp);
      // Memory checkpoints show/hide the recall modal (§6).
      _controller.state.checkpointActive.addListener(_onCheckpointChanged);
    }
  }

  void _onCheckpointChanged() {
    final bool active = _controller.state.checkpointActive.value;
    if (active != _checkpointActive) {
      setState(() {
        _checkpointActive = active;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // WidgetsBindingObserver is MANDATORY here (Section 5.2, v4.3)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // OS Interruption (Section 5.2, v4.3)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_isPaused && !_navigatingToGameOver) {
        setState(() {
          _isPaused = true;
        });
        _controller.pause();
      }
    }
  }

  void _checkGameOver() {
    if (_controller.state.lives.value <= 0 && !_navigatingToGameOver) {
      _navigatingToGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/game-over',
          arguments: {
            'score': _controller.state.score.value,
            'controller': _controller,
          },
        );
      });
    }
  }

  /// Navigates to Game Over when the Burst-mode round timer reaches 0.
  ///
  /// Ignores the initial 0.0 of [GameState.timeRemaining]: only once the timer
  /// has been seeded (>0) does a subsequent 0 count as time-up. Reference: §4.
  void _checkTimeUp() {
    final double remaining = _controller.state.timeRemaining.value;
    if (remaining > 0) {
      _timerStarted = true;
      return;
    }
    if (_timerStarted && !_navigatingToGameOver) {
      _navigatingToGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/game-over',
          arguments: {
            'score': _controller.state.score.value,
            'controller': _controller,
          },
        );
      });
    }
  }

  @override
  void dispose() {
    // Mandatory disposal order (Section 7.2 / Section 5.2):
    // 1. removeObserver
    // 2. remove our listeners
    // 3. controller.dispose() — which owns state.dispose() per the
    //    GameController contract. We must NOT dispose state ourselves here, or
    //    it gets disposed twice ("ValueNotifier used after being disposed").
    WidgetsBinding.instance.removeObserver(this);
    if (_hasInitialised) {
      _controller.state.lives.removeListener(_checkGameOver);
      _controller.state.timeRemaining.removeListener(_checkTimeUp);
      _controller.state.checkpointActive.removeListener(_onCheckpointChanged);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInitialised) {
      return const Scaffold(
        backgroundColor: AppColors.kBackground,
      );
    }

    final double screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Intercept Android back gesture and trigger pause overlay (Section 5.2)
        if (!_isPaused && !_navigatingToGameOver) {
          setState(() {
            _isPaused = true;
          });
          _controller.pause();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.kBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // Layer 1: Flame GameWidget (game built once in didChangeDependencies)
              GameWidget(game: _game),

              // Layer 2: HUD Overlay at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HudOverlay(controller: _controller),
              ),

              // Layer 2b: the round clock is shown numerically in the HUD's
              // left slot (2.0 time economy); the old progress bar was removed.

              // Pause button in bottom right (Section 11.4)
              Positioned(
                bottom: 16.0,
                right: 16.0,
                child: IconButton(
                  icon: const Icon(Icons.pause, size: 32.0),
                  color: AppColors.kSecondaryText,
                  onPressed: () {
                    if (!_isPaused && !_navigatingToGameOver) {
                      setState(() {
                        _isPaused = true;
                      });
                      _controller.pause();
                    }
                  },
                ),
              ),

              // Layer 4: Pause Overlay sliding up from the bottom (Section 5.3)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                bottom: _isPaused ? 0.0 : -screenHeight,
                top: _isPaused ? 0.0 : screenHeight,
                child: Container(
                  color: Colors.black54, // transparent black scrim
                  alignment: Alignment.center,
                  child: PauseOverlay(
                    controller: _controller,
                    onResume: () {
                      setState(() {
                        _isPaused = false;
                      });
                    },
                  ),
                ),
              ),

              // Layer 5: Memory checkpoint recall modal (§6). Blocks gameplay
              // (the game is also paused) until the player submits an answer.
              if (_checkpointActive && _game.activeCheckpoint != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black87,
                    alignment: Alignment.center,
                    child: MemoryCheckpointOverlay(
                      prompt: _game.activeCheckpoint!,
                      onSubmit: (selected) => _game.resolveCheckpoint(selected),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

