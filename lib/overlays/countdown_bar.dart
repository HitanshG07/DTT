import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../game/game_controller.dart';

/// Thin round-countdown progress bar for 2.0 Burst mode.
///
/// Binds to [GameState.timeRemaining] and renders a horizontal fill that drains
/// left→right as the round clock runs down. Turns amber below 20% as a low-time
/// warning. Sits directly beneath the HUD bar.
///
/// Reference: DTT_2.0_ROADMAP.md §4 (Phase 1) — HUD countdown readout.
class CountdownBar extends StatelessWidget {
  final GameController controller;

  /// Bar thickness in logical pixels.
  static const double kHeight = 6.0;

  /// Below this fraction the fill turns amber (low-time warning).
  static const double kWarningFraction = 0.20;

  const CountdownBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final double roundDuration = controller.levelConfig.roundDuration;

    return ValueListenableBuilder<double>(
      valueListenable: controller.state.timeRemaining,
      builder: (context, remaining, child) {
        final double fraction =
            roundDuration <= 0 ? 0.0 : (remaining / roundDuration).clamp(0.0, 1.0);
        final Color fill =
            fraction <= kWarningFraction ? AppColors.kDecayWarning : AppColors.kAccent;

        return SizedBox(
          height: kHeight,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(color: fill),
            ),
          ),
        );
      },
    );
  }
}
