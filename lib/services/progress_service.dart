import 'package:shared_preferences/shared_preferences.dart';

import '../constants/debug_flags.dart';

/// Persists per-level star progress and answers unlock queries (2.0 Phase 4B).
///
/// Stars are stored per level under `dtt_stars_level_<n>` with **best-of**
/// semantics (a level's stars never decrease). A level is unlocked when the
/// previous level has ≥1 star (Level 1 is always unlocked); there are no energy
/// or attempt limits. Mirrors [ScoreService]'s SharedPreferences pattern.
class ProgressService {
  static String _key(int level) => 'dtt_stars_level_$level';

  /// Best stars (0–3) recorded for [level], or 0 if none.
  Future<int> getStars(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(level)) ?? 0;
  }

  /// Records [stars] for [level] if it beats the stored best (best-of).
  /// Returns the resulting best for convenience.
  Future<int> saveStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key(level)) ?? 0;
    if (stars > current) {
      await prefs.setInt(_key(level), stars);
      return stars;
    }
    return current;
  }

  /// Whether [level] is unlocked: Level 1 is always open; otherwise the prior
  /// level must have ≥1 star.
  Future<bool> isUnlocked(int level) async {
    if (DebugFlags.unlockAllLevels) return true; // dev: whole campaign reachable
    if (level <= 1) return true;
    final prevStars = await getStars(level - 1);
    return prevStars >= 1;
  }

  /// Stars for every level in `1..count` (for the map). Index 0 == level 1.
  Future<List<int>> getAllStars(int count) async {
    final prefs = await SharedPreferences.getInstance();
    return [for (int n = 1; n <= count; n++) prefs.getInt(_key(n)) ?? 0];
  }
}
