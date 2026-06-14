import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../game/game_controller.dart';
import '../services/score_service.dart';
import 'forbidden_intro_screen.dart';

/// Game Over Screen (S-08) showing final results and performance metrics.
///
/// Reference: Section 2.3, Section 2.7, Section 2.8, Section 5.1 S-08, Section 5.2, Section 5.3.
class GameOverScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const GameOverScreen({super.key, required this.prefs});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  final ScoreService _scoreService = ScoreService();
  bool _retryEnabled = false;
  int _bestScore = 0;
  bool _isNewBest = false;
  Timer? _retryTimer;
  bool _argsParsed = false;

  late int _finalScore;
  // ignore: unused_field
  late GameController _controller;
  double? _accuracy;
  late int _longestStreak;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsParsed) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _finalScore = args['score'] as int;
      _controller = args['controller'] as GameController;

      // MOCK: accuracy and longestStreak are read from controller/ScoreManager in Stage 4.
      // For Stage 2, we fallback to 87.5 and 12, or use values passed in arguments for testing.
      _accuracy = args.containsKey('accuracy')
          ? args['accuracy'] as double?
          : 87.5; // MOCK: accuracy = 87.5 — replaced in Stage 4

      _longestStreak = args.containsKey('longestStreak')
          ? args['longestStreak'] as int
          : 12; // MOCK: longestStreak = 12 — replaced in Stage 4

      _argsParsed = true;

      _saveAndLoadScores();
    }
  }

  @override
  void initState() {
    super.initState();
    // Retry button enabled after 1 second (FR-11, Section 5.2)
    _retryTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _retryEnabled = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveAndLoadScores() async {
    // 1. Get current best before saving
    final currentBest = await _scoreService.getBestScore();
    if (_finalScore > currentBest) {
      _isNewBest = true;
    }

    // 2. Call ScoreService.saveBestScore(score) — round ended naturally (Section 2.7, 5.2)
    await _scoreService.saveBestScore(_finalScore);

    // 3. Read updated best score
    final updatedBest = await _scoreService.getBestScore();
    if (mounted) {
      setState(() {
        _bestScore = updatedBest;
      });
    }
  }

  String _getPerformanceMessage(int score) {
    if (score < 50) return "Keep Practising";
    if (score < 100) return "Nice Start!";
    if (score < 200) return "Sharp Focus!";
    if (score < 350) return "On Fire!";
    if (score < 500) return "Elite Control!";
    return "Untouchable!";
  }

  @override
  Widget build(BuildContext context) {
    if (!_argsParsed) {
      return const Scaffold(
        backgroundColor: AppColors.kBackground,
      );
    }

    final performanceMsg = _getPerformanceMessage(_finalScore);

    // Format Accuracy text: null -> display "—" (em dash), else display "XX.X%" (Section 2.8)
    final String accuracyText = _accuracy == null
        ? "—"
        : "${_accuracy!.toStringAsFixed(1)}%";

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // GAME OVER title
              const Text(
                "GAME OVER",
                style: TextStyle(
                  fontFamily: AppFonts.kFontDisplay,
                  fontSize: 36.0,
                  color: AppColors.kPrimaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),

              // Score displays with count-up animation 600 ms (Section 5.3)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: _finalScore.toDouble()),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Text(
                    "${value.round()}",
                    style: const TextStyle(
                      fontFamily: AppFonts.kFontDisplay,
                      fontSize: 64.0,
                      color: AppColors.kAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),

              if (_isNewBest) ...[
                const SizedBox(height: 8.0),
                const Text(
                  "✦ NEW BEST! ✦",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    fontSize: 16.0,
                    color: AppColors.kAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(flex: 2),

              // 3-column stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // BEST
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "$_bestScore",
                          style: const TextStyle(
                            fontFamily: AppFonts.kFontDisplay,
                            fontSize: 20.0,
                            color: AppColors.kPrimaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          "BEST",
                          style: TextStyle(
                            fontFamily: AppFonts.kFontBody,
                            fontSize: 11.0,
                            color: AppColors.kSecondaryText,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ACCURACY
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          accuracyText,
                          style: const TextStyle(
                            fontFamily: AppFonts.kFontDisplay,
                            fontSize: 20.0,
                            color: AppColors.kPrimaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          "ACCURACY",
                          style: TextStyle(
                            fontFamily: AppFonts.kFontBody,
                            fontSize: 11.0,
                            color: AppColors.kSecondaryText,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // STREAK
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "$_longestStreak",
                          style: const TextStyle(
                            fontFamily: AppFonts.kFontDisplay,
                            fontSize: 20.0,
                            color: AppColors.kPrimaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          "STREAK",
                          style: TextStyle(
                            fontFamily: AppFonts.kFontBody,
                            fontSize: 11.0,
                            color: AppColors.kSecondaryText,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),

              // Performance Message
              Text(
                performanceMsg,
                style: const TextStyle(
                  fontFamily: AppFonts.kFontBody,
                  fontSize: 16.0,
                  color: AppColors.kSecondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(flex: 3),

              // RETRY Button
              SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _retryEnabled ? AppColors.kAccent : Colors.grey[800],
                    foregroundColor: _retryEnabled ? AppColors.kPrimaryText : Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _retryEnabled
                      ? () {
                          // Fast cross-fade 200 ms (Section 5.3)
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              settings: const RouteSettings(name: '/forbidden-intro'),
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  ForbiddenIntroScreen(prefs: widget.prefs),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 200),
                            ),
                          );
                        }
                      : null,
                  child: const Text(
                    "RETRY",
                    style: TextStyle(
                      fontFamily: AppFonts.kFontDisplay,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // HOME Button
              SizedBox(
                width: double.infinity,
                height: 56.0,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.kSecondaryText),
                    foregroundColor: AppColors.kPrimaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/start', (_) => false);
                  },
                  child: const Text(
                    "HOME",
                    style: TextStyle(
                      fontFamily: AppFonts.kFontDisplay,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

