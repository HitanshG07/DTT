import 'game_state.dart';
import 'config/level_config.dart';

/// Abstract interface for controlling the game loop.
///
/// Exposes [GameState] for UI binding and lifecycle methods.
/// Both MockGameController (Stage 1) and RealGameController (Stage 4)
/// implement this interface. The swap is a one-line constructor change
/// in game_screen.dart.
///
/// Zero Flame imports.
///
/// Reference: Section 10.1 -- GameController interface.
abstract class GameController {
  /// The observable game state. UI binds to these ValueNotifiers.
  GameState get state;

  /// The active level configuration.
  LevelConfig get levelConfig;

  /// Starts the game loop.
  void start();

  /// Pauses the game loop. Objects freeze in place.
  void pause();

  /// Resumes a paused game loop.
  void resume();

  /// Restarts the game session (resets state).
  void restart();

  /// Quits the current round. Score is discarded (Section 2.7).
  void quit();

  /// Releases all resources. Calls state.dispose().
  void dispose();

  /// The final round accuracy percentage, or null if no taps registered.
  double? get accuracy;

  /// The longest consecutive correct tap streak.
  int get longestStreak;
}
