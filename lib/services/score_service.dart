import 'package:shared_preferences/shared_preferences.dart';

/// Persists and retrieves the player's best score.
///
/// Uses shared_preferences with key 'dtt_best_score'.
///
/// Reference: FR-12, Section 2.7.
class ScoreService {
  static const String _key = 'dtt_best_score';

  /// Returns the player's best score, or 0 if no score has been saved.
  Future<int> getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  /// Saves [score] as the new best if it exceeds the current best.
  ///
  /// Performs a read-before-write: only writes if [score] > current best.
  ///
  /// **Contract:** This method must ONLY be called when a round ends
  /// naturally (lives reach 0). It must NEVER be called when the player
  /// quits from the Pause screen. The caller enforces this rule -- this
  /// service has no knowledge of round-end vs quit state.
  /// Reference: Section 2.7 -- Quit Behaviour.
  Future<void> saveBestScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    if (score > current) {
      await prefs.setInt(_key, score);
    }
  }
}
