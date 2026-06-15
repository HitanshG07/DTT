import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for playing audio sound effects with support for pitch modifications.
/// Respects the 'dtt_audio_enabled' preference.
///
/// Reference: Sections 6.2, 7.2.
class AudioService {
  final SharedPreferences _prefs;

  /// Feature flag to enable/disable the pitch ladder effect (Risk 1, Section 1.5).
  bool pitchLadderEnabled = true;

  /// Lazy initializer future for correct tap AudioPool.
  Future<void>? _initPoolFuture;
  AudioPool? _correctTapPool;

  /// Sample timestamp map for 50ms debounce logic.
  final Map<String, DateTime> _lastPlayed = {};

  AudioService(this._prefs);

  /// Helper to check if audio is enabled.
  bool get isAudioEnabled => _prefs.getBool('dtt_audio_enabled') ?? true;

  /// Normalize filename to match preloaded file patterns (handling potential lack of underscores).
  String _normalizeFilename(String filename) {
    final clean = filename.toLowerCase().replaceAll('_', '');
    switch (clean) {
      case 'correcttap.ogg':
        return 'correct_tap.ogg';
      case 'wrongtap.ogg':
        return 'wrong_tap.ogg';
      case 'comboup.ogg':
        return 'combo_up.ogg';
      case 'combobreak.ogg':
        return 'combo_break.ogg';
      case 'milestone.ogg':
        return 'milestone.ogg';
      case 'roundstart.ogg':
        return 'round_start.ogg';
      case 'lifelost.ogg':
        return 'life_lost.ogg';
      case 'gameover.ogg':
        return 'game_over.ogg';
      case 'newbest.ogg':
        return 'new_best.ogg';
      case 'forbiddenchange.ogg':
        return 'forbidden_change.ogg';
      default:
        return filename;
    }
  }

  /// Check if a sound file is exempt from the 50ms debounce.
  bool _isExempt(String normalized) {
    return normalized == 'milestone.ogg' ||
        normalized == 'game_over.ogg' ||
        normalized == 'new_best.ogg' ||
        normalized == 'forbidden_change.ogg';
  }

  /// Get or initialize the AudioPool for correct_tap.ogg.
  Future<AudioPool> _getOrCreateCorrectTapPool() async {
    if (_correctTapPool != null) return _correctTapPool!;
    _initPoolFuture ??= _initPool();
    await _initPoolFuture;
    return _correctTapPool!;
  }

  Future<void> _initPool() async {
    _correctTapPool = await FlameAudio.createPool(
      'correct_tap.ogg',
      maxPlayers: 16,
    );
  }

  /// Plays a sound effect, with support for pitch modifications.
  /// Enforces 50ms debounce for identical sound files.
  Future<void> play(String filename, {double pitch = 1.0}) async {
    if (!isAudioEnabled) return;

    final String normalized = _normalizeFilename(filename);

    final now = DateTime.now();
    if (!_isExempt(normalized)) {
      final lastPlayTime = _lastPlayed[normalized];
      if (lastPlayTime != null && now.difference(lastPlayTime).inMilliseconds < 50) {
        // Drop the play call to prevent audio clipping
        return;
      }
      _lastPlayed[normalized] = now;
    }

    try {
      if (normalized == 'correct_tap.ogg') {
        final pool = await _getOrCreateCorrectTapPool();
        // Capture players currently playing to set pitch on the player used
        // ignore: invalid_use_of_visible_for_testing_member
        final oldKeys = pool.currentPlayers.keys.toSet();
        await pool.start();
        // ignore: invalid_use_of_visible_for_testing_member
        final newKeys = pool.currentPlayers.keys.toSet();
        final addedKeys = newKeys.difference(oldKeys);
        if (addedKeys.isNotEmpty) {
          // ignore: invalid_use_of_visible_for_testing_member
          final player = pool.currentPlayers[addedKeys.first];
          if (player != null) {
            await player.setPlaybackRate(pitch);
          }
        }
      } else {
        final player = await FlameAudio.play(normalized);
        if (pitch != 1.0) {
          await player.setPlaybackRate(pitch);
        }
      }
    } catch (e) {
      // Gracefully catch playback failures in environments without audio support
    }
  }
}
