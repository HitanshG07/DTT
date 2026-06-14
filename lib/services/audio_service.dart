import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for playing audio sound effects with support for pitch modifications.
/// Respects the 'dtt_audio_enabled' preference.
///
/// Reference: Sections 6.2, 7.2.
class AudioService {
  final SharedPreferences _prefs;

  /// Feature flag to enable/disable the pitch ladder effect (Risk 1, Section 1.5).
  bool pitchLadderEnabled = true;

  AudioService(this._prefs);

  /// Helper to check if audio is enabled.
  bool get isAudioEnabled => _prefs.getBool('dtt_audio_enabled') ?? true;

  /// MOCK: Placeholder for playing sound effects in Stage 2.
  /// Real implementation is added in Stage 5.
  Future<void> play(String filename, {double pitch = 1.0}) async {
    // MOCK: AudioService playback is replaced in Stage 5 with real FlameAudio calls.
    if (!isAudioEnabled) return;
  }
}
