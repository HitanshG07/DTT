import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import '../game/effects/combo_decay_arc.dart';
import '../game/effects/combo_flash.dart';

/// Combo Decay Badge overlay widget that shows multiplier and visual decay arc.
///
/// Reference: Section 4.4, Section 6.4, Section 11.4.
class ComboDecayBadge extends StatelessWidget {
  final int multiplier;
  final double decayProgress;

  const ComboDecayBadge({
    super.key,
    required this.multiplier,
    required this.decayProgress,
  });

  @override
  Widget build(BuildContext context) {
    return ComboFlash(
      multiplier: multiplier,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decay arc border
          ComboDecayArc(
            decayProgress: decayProgress,
            size: AppSizes.kComboBadgeSize,
          ),
          // Badge background and text
          Container(
            width: AppSizes.kComboBadgeSize - 6.0,
            height: AppSizes.kComboBadgeSize - 6.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ignore: deprecated_member_use
              color: AppColors.kAccent.withOpacity(0.20),
            ),
            alignment: Alignment.center,
            child: Text(
              "x$multiplier",
              style: const TextStyle(
                fontFamily: AppFonts.kFontDisplay,
                fontSize: 14.0,
                color: AppColors.kPrimaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

