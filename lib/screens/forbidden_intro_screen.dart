import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../game/config/game_constants.dart';
import '../game/config/shape_type.dart';
import '../game/shapes/base_shape.dart';
import '../game/game_controller.dart';
import '../game/real_game_controller.dart';
import '../game/managers/forbidden_manager.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import 'game_screen.dart';

/// Forbidden Intro Screen (S-05) that shows the forbidden shape for a few seconds.
///
/// Reference: Section 4.6, Section 5.1 S-05, Section 5.3.
class ForbiddenIntroScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final GameController? mockController; // For testing injection
  final HapticsService? haptics;
  final AudioService? audio;

  const ForbiddenIntroScreen({
    super.key,
    required this.prefs,
    this.mockController,
    this.haptics,
    this.audio,
  });

  @override
  State<ForbiddenIntroScreen> createState() => _ForbiddenIntroScreenState();
}

class _ForbiddenIntroScreenState extends State<ForbiddenIntroScreen> with SingleTickerProviderStateMixin {
  late final GameController _controller;
  int _countdown = GameConstants.kForbiddenIntroDurationS; // 3 seconds
  Timer? _timer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize controller using RealGameController (Stage 4)
    _controller = widget.mockController ?? RealGameController(
      audioService: widget.audio,
      hapticsService: widget.haptics,
      reduceFlashing: widget.prefs.getBool('dtt_reduce_flashing') ?? false,
    );

    // Select forbidden shape using ForbiddenManager before screen appears (Section 2.5, 5.2)
    final ShapeType selectedForbidden = ForbiddenManager.selectForbidden(
      config: _controller.levelConfig,
      previousForbidden: _controller.state.forbiddenShape.value,
    );
    _controller.state.forbiddenShape.value = selectedForbidden;

    _controller.start();

    // 2. Pulse animation for blue border (cycles 0.6 -> 1.0 at 1s interval) (Section 6.4)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);

    // 3. Start countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _navigateToGame();
      }
    });
  }

  void _navigateToGame() {
    if (!mounted) return;
    // Transition: instant cut 0 ms (Section 5.3 "Seamless — game already loaded")
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        settings: RouteSettings(
          name: '/game',
          arguments: {'controller': _controller},
        ),
        pageBuilder: (context, animation, secondaryAnimation) => const GameScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the forbidden shape from controller state
    // Default to circle shape for fallback/mock display
    final forbiddenType = _controller.state.forbiddenShape.value ?? ShapeType.circle;
    final shapePainter = BaseShape.forType(forbiddenType);
    final shapeName = forbiddenType.name.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "DON'T TAP",
              style: TextStyle(
                fontFamily: AppFonts.kFontBody,
                fontSize: 16.0,
                color: AppColors.kSecondaryText,
                letterSpacing: 3.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32.0),
            // Forbidden Shape wrapped in pulsing blue border
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    width: 140.0,
                    height: 140.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.kAccent,
                        width: 2.0,
                      ),
                    ),
                    child: SizedBox(
                      width: 100.0,
                      height: 100.0,
                      child: CustomPaint(
                        painter: ShapePainter(shape: shapePainter),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            // Shape name
            Text(
              shapeName,
              style: const TextStyle(
                fontFamily: AppFonts.kFontDisplay,
                fontSize: 24.0,
                color: AppColors.kPrimaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40.0),
            // Countdown number (3 -> 2 -> 1)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Text(
                "$_countdown",
                key: ValueKey<int>(_countdown),
                style: const TextStyle(
                  fontFamily: AppFonts.kFontDisplay,
                  fontSize: 64.0,
                  color: AppColors.kAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48.0),
            const Text(
              "Memorise the shape above",
              style: TextStyle(
                fontFamily: AppFonts.kFontBody,
                fontSize: 13.0,
                color: AppColors.kSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  final BaseShape shape;

  ShapePainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.kPrimaryText
      ..style = PaintingStyle.fill;
    shape.paintShape(canvas, size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
