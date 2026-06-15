import 'package:flutter/foundation.dart';
import '../config/game_constants.dart';

/// Manages the player's lives, updates the lives notifier, and triggers round end.
///
/// Reference: Section 2.4, FR-05, Section 10.3 Stage 4.
class LifeManager {
  final ValueNotifier<int> _livesNotifier;
  final VoidCallback? onRoundEnd;

  LifeManager(this._livesNotifier, {this.onRoundEnd}) {
    _livesNotifier.addListener(_onLivesChanged);
  }

  int get lives => _livesNotifier.value;

  void _onLivesChanged() {
    if (_livesNotifier.value <= 0) {
      onRoundEnd?.call();
    }
  }

  /// Decrements lives by 1.
  void decrement() {
    if (_livesNotifier.value > 0) {
      _livesNotifier.value -= 1;
    }
  }

  /// Resets lives to default starting lives.
  void reset() {
    _livesNotifier.value = GameConstants.kLives;
  }

  /// Cleans up the listener.
  void dispose() {
    _livesNotifier.removeListener(_onLivesChanged);
  }
}
