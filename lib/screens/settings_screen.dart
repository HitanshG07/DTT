import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

/// Settings Screen (S-04) containing toggles for audio and haptic feedback.
///
/// Reference: Section 5.1 S-04, Section 5.2.
class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _audioEnabled;
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    // Default to true if key is not present (Section 5.1 S-04)
    _audioEnabled = widget.prefs.getBool('dtt_audio_enabled') ?? true;
    _hapticsEnabled = widget.prefs.getBool('dtt_haptics_enabled') ?? true;
  }

  Future<void> _updateAudioSetting(bool val) async {
    setState(() {
      _audioEnabled = val;
    });
    // Saved immediately on change, not on close (Section 5.2)
    await widget.prefs.setBool('dtt_audio_enabled', val);
  }

  Future<void> _updateHapticsSetting(bool val) async {
    setState(() {
      _hapticsEnabled = val;
    });
    // Saved immediately on change, not on close (Section 5.2)
    await widget.prefs.setBool('dtt_haptics_enabled', val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        title: const Text(
          "SETTINGS",
          style: TextStyle(
            fontFamily: AppFonts.kFontDisplay,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.kPrimaryText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        children: [
          // Row 1: Sound Effects Card
          Card(
            color: AppColors.kSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SwitchListTile(
                // ignore: deprecated_member_use
                activeColor: AppColors.kAccent,
                title: const Text(
                  "Sound Effects",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kPrimaryText,
                  ),
                ),
                subtitle: const Text(
                  "Tap sounds, combos, game over",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    fontSize: 13.0,
                    color: AppColors.kSecondaryText,
                  ),
                ),
                value: _audioEnabled,
                onChanged: _updateAudioSetting,
              ),
            ),
          ),
          const SizedBox(height: 16.0), // 16 px gap between rows
          // Row 2: Haptic Feedback Card
          Card(
            color: AppColors.kSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SwitchListTile(
                // ignore: deprecated_member_use
                activeColor: AppColors.kAccent,
                title: const Text(
                  "Haptic Feedback",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kPrimaryText,
                  ),
                ),
                subtitle: const Text(
                  "Vibration on correct and wrong taps",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    fontSize: 13.0,
                    color: AppColors.kSecondaryText,
                  ),
                ),
                value: _hapticsEnabled,
                onChanged: _updateHapticsSetting,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
