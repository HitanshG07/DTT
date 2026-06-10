import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: prefer_const_constructors

/// ─────────────────────────────────────────────────────────────
/// Stage 0 · Section 8.7 Verification
/// ─────────────────────────────────────────────────────────────
/// Step 1: Flame renders — solid black screen at 60 fps
/// Step 2: flame_audio — tap to play test.ogg (commented out
///         until valid .ogg files are added)
/// Step 3: shared_preferences — write, hot-restart, read
/// ─────────────────────────────────────────────────────────────
///
/// AFTER all 3 verifications pass on physical device,
/// this file will be replaced by the Stage 1 entry point.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 3: shared_preferences verification ──
  final prefs = await SharedPreferences.getInstance();

  final existingValue = prefs.getInt('verify_key');
  if (existingValue != null) {
    debugPrint(
        '✅ Step 3 PASS: shared_preferences persisted value = $existingValue');
  } else {
    await prefs.setInt('verify_key', 42);
    debugPrint(
        '📝 Step 3: Wrote verify_key=42. Hot-restart to verify persistence.');
  }

  runApp(const VerificationApp());
}

class VerificationApp extends StatelessWidget {
  const VerificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Don't Tap That — Stage 0 Verification",
      home: GameWidget<TestGame>.controlled(
        gameFactory: TestGame.new,
      ),
    );
  }
}

/// Step 1: Flame renders — a solid black screen at 60 fps.
/// Step 2: Tap anywhere to test audio playback (uncomment when .ogg ready).
class TestGame extends FlameGame with TapCallbacks {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    debugPrint(
        '✅ Step 1: Flame game loaded. If you see a black screen, Flame renders.');

    // Step 2: Pre-load the test audio file
    // Uncomment the lines below once a valid .ogg is available:
    // try {
    //   await FlameAudio.audioCache.load('test.ogg');
    //   debugPrint('✅ Step 2: Audio file loaded successfully.');
    // } catch (e) {
    //   debugPrint('❌ Step 2 FAIL: Audio load error: $e');
    // }
  }

  @override
  void onTapDown(TapDownEvent event) {
    debugPrint('👆 Tap detected at ${event.localPosition}');

    // Step 2: Play the test audio on tap
    // Uncomment once a valid .ogg is available:
    // try {
    //   FlameAudio.play('test.ogg');
    //   debugPrint('✅ Step 2: Audio played on tap.');
    // } catch (e) {
    //   debugPrint('❌ Step 2 FAIL: Audio play error: $e');
    // }
  }
}
