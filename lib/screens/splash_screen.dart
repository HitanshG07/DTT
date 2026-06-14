import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'start_screen.dart';
import 'how_to_play_screen.dart';

/// Splash Screen (S-01) that handles pre-loading assets, checks the
/// first-launch flag, and auto-advances.
///
/// Reference: Section 5.1 S-01, Section 5.2, Section 5.3, Section 6.2.
class SplashScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SplashScreen({super.key, required this.prefs});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAssetsAndNavigate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadAssetsAndNavigate() async {
    try {
      // 1. Load all 10 audio files (Section 6.2)
      await FlameAudio.audioCache.loadAll([
        'correct_tap.ogg',
        'wrong_tap.ogg',
        'combo_up.ogg',
        'combo_break.ogg',
        'milestone.ogg',
        'round_start.ogg',
        'life_lost.ogg',
        'game_over.ogg',
        'new_best.ogg',
        'forbidden_change.ogg',
      ]);
    } catch (e) {
      // If assets are not present or fail to load in Stage 2 mock, we catch and proceed.
      // No print() statements allowed (Architectural Rules 7.2)
    }

    // 2. Read first launch flag from shared_preferences
    final isFirstLaunch = widget.prefs.getBool('dtt_first_launch') ?? true;

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // 3. Navigate with cross-fade 350 ms transition (Section 5.3)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          if (isFirstLaunch) {
            return HowToPlayScreen(prefs: widget.prefs);
          } else {
            return StartScreen(prefs: widget.prefs);
          }
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "DON'T TAP THAT",
              style: TextStyle(
                fontFamily: AppFonts.kFontDisplay,
                fontSize: 32.0,
                color: AppColors.kPrimaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.kAccent),
              ),
          ],
        ),
      ),
    );
  }
}
