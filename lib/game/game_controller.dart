import 'game_state.dart';

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

  /// Starts the game loop.
  void start();

  /// Pauses the game loop. Objects freeze in place.
  void pause();

  /// Resumes a paused game loop.
  void resume();

  /// Quits the current round. Score is discarded (Section 2.7).
  void quit();

  /// Releases all resources. Calls state.dispose().
  void dispose();
}
