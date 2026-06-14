import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import '../game/config/game_constants.dart';

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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decay arc border CustomPaint
        SizedBox(
          width: AppSizes.kComboBadgeSize,
          height: AppSizes.kComboBadgeSize,
          child: CustomPaint(
            painter: ComboDecayArcPainter(decayProgress: decayProgress),
          ),
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
    );
  }
}

/// Painter for the combo decay arc.
class ComboDecayArcPainter extends CustomPainter {
  final double decayProgress;

  ComboDecayArcPainter({required this.decayProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 3.0) / 2;

    // Determine color based on remaining decay percentage (Section 4.1, 4.4)
    // Amber / kDecayWarning below 20% decay progress, else Clean Blue / kAccent
    final color = decayProgress < GameConstants.kComboDecayWarningPercent
        ? AppColors.kDecayWarning
        : AppColors.kAccent;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // MOCK: In Stage 2 we have a static full arc or dynamic arc bound to mock notifier.
    // STAGE 5: replace static arc with animated ComboDecayArc effect.
    final double sweepAngle = 2 * pi * decayProgress;

    // Draw arc from top (-pi / 2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ComboDecayArcPainter oldDelegate) {
    return oldDelegate.decayProgress != decayProgress;
  }
}
