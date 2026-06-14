import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_colors.dart';
import 'constants/app_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/start_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/forbidden_intro_screen.dart';
import 'screens/game_screen.dart';
import 'screens/game_over_screen.dart';
import 'services/haptics_service.dart';
import 'services/audio_service.dart';

/// The root MaterialApp for the "Don't Tap That" module.
/// It configures the global dark theme, font family, and route table.
///
/// Reference: Section 2, 4.1, 4.3, 5.2, 7.1.
class DttApp extends StatefulWidget {
  final SharedPreferences prefs;

  const DttApp({super.key, required this.prefs});

  @override
  State<DttApp> createState() => _DttAppState();
}

class _DttAppState extends State<DttApp> {
  late final HapticsService hapticsService;
  late final AudioService audioService;

  @override
  void initState() {
    super.initState();
    hapticsService = HapticsService(widget.prefs);
    audioService = AudioService(widget.prefs);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Don't Tap That",
      // Dark theme only. No light theme, no system theme switching (Section 2, Day 3 app.dart).
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.kBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.kAccent,
          brightness: Brightness.dark,
        ),
        fontFamily: AppFonts.kFontBody, // Inter is the global body font (Section 4.3)
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(prefs: widget.prefs),
        '/start': (context) => StartScreen(prefs: widget.prefs),
        '/how-to-play': (context) => HowToPlayScreen(prefs: widget.prefs),
        '/settings': (context) => SettingsScreen(prefs: widget.prefs),
        '/game': (context) => GameScreen(
              prefs: widget.prefs,
              haptics: hapticsService,
            ),
        '/dont-tap-that/tutorial': (context) => const Scaffold(
              body: Center(
                child: Text(
                  "Tutorial — coming soon",
                  style: TextStyle(
                    fontFamily: AppFonts.kFontBody,
                    color: AppColors.kPrimaryText,
                  ),
                ),
              ),
            ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/forbidden-intro') {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => ForbiddenIntroScreen(
              prefs: widget.prefs,
              haptics: hapticsService,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          );
        }
        if (settings.name == '/game-over') {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => GameOverScreen(
              prefs: widget.prefs,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          );
        }
        return null;
      },
    );
  }
}
