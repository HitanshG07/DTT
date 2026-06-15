import '../services/score_service.dart';
import 'game_controller.dart';
import 'game_state.dart';
import 'dtt_game.dart';
import 'score_manager.dart';
import 'managers/life_manager.dart';
import 'config/level_config.dart';
import 'config/level_registry.dart';

/// Real game controller implementation.
///
/// Owns the [DttGame] instance, manages the managers, handles scoring, and updates state.
///
/// Reference: Section 2.7, Section 10.3 Stage 4, FR-12.
class RealGameController implements GameController {
  @override
  final GameState state = GameState();

  @override
  final LevelConfig levelConfig;

  late final ScoreManager scoreManager;
  late final LifeManager lifeManager;
  final ScoreService _scoreService = ScoreService();

  DttGame? game;

  RealGameController({int level = 1}) : levelConfig = LevelRegistry.forLevel(level) {
    scoreManager = ScoreManager(state);
    lifeManager = LifeManager(state.lives, onRoundEnd: _handleRoundEnd);
  }

  void _handleRoundEnd() {
    // Write to ScoreService only if new best on natural round end (FR-12, Section 2.7, 5.2)
    final score = state.score.value;
    _scoreService.saveBestScore(score);
    // Pause game components on round end
    game?.paused = true;
  }

  @override
  void start() {
    resume();
  }

  @override
  void pause() {
    game?.paused = true;
  }

  @override
  void resume() {
    game?.paused = false;
  }

  @override
  void restart() {
    state.score.value = 0;
    state.multiplier.value = 1;
    state.decayProgress.value = 1.0;
    state.forbiddenShape.value = null;
    lifeManager.reset();
  }

  @override
  void quit() {
    // Discards score (does NOT write to ScoreService) (Section 2.7)
    pause();
  }

  @override
  void dispose() {
    lifeManager.dispose();
    state.dispose();
  }

  @override
  double? get accuracy => scoreManager.getAccuracyPercent();

  @override
  int get longestStreak => scoreManager.longestStreak;
}
