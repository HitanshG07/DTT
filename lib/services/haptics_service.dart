import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper for Flutter's built-in haptic services.
/// Checks the 'dtt_haptics_enabled' preference before invoking haptic feedback.
///
/// Reference: Section 6.5, Architectural Rules 7.2.
class HapticsService {
  final SharedPreferences _prefs;

  HapticsService(this._prefs);

  bool get hapticsEnabled => _prefs.getBool('dtt_haptics_enabled') ?? true;

  Future<void> correct() async {
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> wrong() async {
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> milestone() async {
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> lifeLost() async {
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> selectionClick() async {
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> heavyImpact() async {
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> mediumImpact() async {
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> lightImpact() async {
    if (hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }
  }
}
