import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../services/score_service.dart';

/// Start Screen (S-02) displaying the title, personal best, and buttons.
///
/// Reference: Section 5.1 S-02, Section 5.2, Section 11.2.
class StartScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const StartScreen({super.key, required this.prefs});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final ScoreService _scoreService = ScoreService();
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _refreshBestScore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshBestScore();
  }

  Future<void> _refreshBestScore() async {
    final score = await _scoreService.getBestScore();
    if (mounted) {
      setState(() {
        _bestScore = score;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Stack(
        children: [
          // Settings button in the top-right corner
          Positioned(
            top: 48.0,
            right: 16.0,
            child: IconButton(
              icon: const Icon(Icons.settings),
              color: AppColors.kSecondaryText,
              onPressed: () {
                Navigator.pushNamed(context, '/settings').then((_) => _refreshBestScore());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Title (Section 4.3, 11.2)
                const Text(
                  "DON'T TAP THAT",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontDisplay,
                    fontSize: 40.0,
                    color: AppColors.kPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                // Thin blue accent rule (Section 11.2)
                Container(
                  width: 120.0,
                  height: 2.0,
                  color: AppColors.kAccent,
                ),
                const Spacer(flex: 2),
                // Best score label
                const Text(
                  "BEST",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    fontSize: 12.0,
                    color: AppColors.kSecondaryText,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                // Best score value
                // MOCK: replaced in Stage 4 via ScoreService.getBestScore() — already wired, no change needed.
                Text(
                  "$_bestScore",
                  style: const TextStyle(
                    fontFamily: AppFonts.kFontDisplay,
                    fontSize: 48.0,
                    color: AppColors.kPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(flex: 2),
                // Play Button
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kAccent,
                      foregroundColor: AppColors.kPrimaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/forbidden-intro').then((_) => _refreshBestScore());
                    },
                    child: const Text(
                      "PLAY",
                      style: TextStyle(
                        fontFamily: AppFonts.kFontDisplay,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                // How to play text link
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/how-to-play');
                  },
                  child: const Text(
                    "how to play?",
                    style: TextStyle(
                      fontFamily: AppFonts.kFontBody,
                      fontSize: 14.0,
                      color: AppColors.kSecondaryText,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
