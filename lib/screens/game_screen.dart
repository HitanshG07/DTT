import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../game/dtt_game.dart';
import '../game/game_controller.dart';
import '../overlays/hud_overlay.dart';
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
  bool _isPaused = false;
  bool _hasInitialised = false;
  bool _navigatingToGameOver = false;

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

      // Add listener to lives to navigate to Game Over when lives reach 0 (Section 5.2)
      _controller.state.lives.addListener(_checkGameOver);
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

  @override
  void dispose() {
    // Mandatory disposal order (Section 7.2 / Section 5.2):
    // 1. removeObserver
    // 2. state.dispose()
    // 3. controller.dispose()
    WidgetsBinding.instance.removeObserver(this);
    if (_hasInitialised) {
      _controller.state.lives.removeListener(_checkGameOver);
      _controller.state.dispose(); // ValueNotifier disposal rule (Section 7.2)
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
              // Layer 1: Flame GameWidget
              GameWidget(
                game: DttGame(
                  controller: _controller,
                  levelConfig: _controller.levelConfig,
                  correctColor: AppColors.kCorrect,
                  forbiddenColor: AppColors.kWrong,
                ),
              ),

              // Layer 2: HUD Overlay at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HudOverlay(controller: _controller),
              ),

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
            ],
          ),
        ),
      ),
    );
  }
}

