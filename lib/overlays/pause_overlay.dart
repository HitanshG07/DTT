import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../game/game_controller.dart';

/// Pause Overlay widget (S-07) showing Resume, Restart, and Quit options.
///
/// Reference: Section 2.7, Section 5.1 S-07, Section 5.2, Section 5.3.
class PauseOverlay extends StatelessWidget {
  final GameController controller;
  final VoidCallback onResume;

  const PauseOverlay({
    super.key,
    required this.controller,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Card(
          color: AppColors.kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title (Section 11.5)
                const Text(
                  "PAUSED",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontDisplay,
                    fontSize: 24.0,
                    color: AppColors.kPrimaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24.0),

                // 1. RESUME Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
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
                      controller.resume();
                      onResume();
                    },
                    child: const Text(
                      "RESUME",
                      style: TextStyle(
                        fontFamily: AppFonts.kFontDisplay,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // 2. RESTART Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.kSecondaryText),
                      foregroundColor: AppColors.kPrimaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      controller.quit();
                      // Full state reset and restart round
                      Navigator.pushReplacementNamed(context, '/forbidden-intro');
                    },
                    child: const Text(
                      "RESTART",
                      style: TextStyle(
                        fontFamily: AppFonts.kFontDisplay,
                        fontSize: 16.0,
                        color: AppColors.kPrimaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // 3. QUIT Button
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.kWrong),
                      foregroundColor: AppColors.kWrong,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Discard score, do not save to ScoreService (Section 2.7, 5.2)
                      controller.quit();
                      Navigator.pushNamedAndRemoveUntil(context, '/start', (_) => false);
                    },
                    child: const Text(
                      "QUIT",
                      style: TextStyle(
                        fontFamily: AppFonts.kFontDisplay,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
