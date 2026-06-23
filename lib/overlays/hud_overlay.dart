import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import '../game/game_controller.dart';
import '../game/shapes/base_shape.dart';
import '../game/effects/forbidden_pulse.dart';
import '../game/effects/proximity_pulse.dart';
import 'combo_decay_badge.dart';

/// HUD Overlay widget (S-06) showing the round-time countdown, score, combo
/// badge, and forbidden shape thumbnail.
///
/// 2.0 Burst mode uses a **time economy** (no lives): the left slot shows a
/// numeric mm:ss countdown bound to [GameState.timeRemaining], replacing the
/// old hearts. Reference: Section 4.4, Section 11.4; DTT_2.0_ROADMAP.md §5.
class HudOverlay extends StatelessWidget {
  final GameController controller;

  const HudOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    return Container(
      height: AppSizes.kHudHeight,
      width: double.infinity,
      color: AppColors.kSurface,
      alignment: Alignment.center,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT — Round-time countdown (mm:ss). Burst mode's time
                  // economy uses this in place of lives/hearts; turns amber in
                  // the final 10 s as a low-time warning (static colour change,
                  // seizure-safe — no flashing).
                  ValueListenableBuilder<double>(
                    valueListenable: state.timeRemaining,
                    builder: (context, remaining, child) {
                      final int secs = remaining.ceil().clamp(0, 3599);
                      final String mmss =
                          '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
                      final bool urgent = secs <= 10;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mmss,
                            style: TextStyle(
                              fontFamily: AppFonts.kFontDisplay,
                              fontSize: AppSizes.kHudTimeFontSize,
                              color: urgent
                                  ? AppColors.kDecayWarning
                                  : AppColors.kPrimaryText,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Text(
                              "TIME",
                              style: TextStyle(
                                fontFamily: AppFonts.kFontBody,
                                fontSize: AppSizes.kForbiddenLabelFontSize,
                                color: AppColors.kSecondaryText,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // CENTRE — Score (the HUD hero) with a small combo badge
                  // tucked at its lower-right. The 0-opacity placeholder
                  // reserves the badge's width so the score doesn't shift when
                  // the combo appears or clears.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: state.score,
                        builder: (context, scoreValue, child) {
                          return Text(
                            "$scoreValue",
                            style: const TextStyle(
                              fontFamily: AppFonts.kFontDisplay,
                              fontSize: AppSizes.kHudScoreFontSize,
                              color: AppColors.kPrimaryText,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6.0),
                      ValueListenableBuilder<int>(
                        valueListenable: state.multiplier,
                        builder: (context, multValue, child) {
                          final Widget badge = multValue <= 1
                              ? const Opacity(
                                  opacity: 0.0,
                                  child: ComboDecayBadge(
                                    multiplier: 2,
                                    decayProgress: 0.5,
                                  ),
                                )
                              : ValueListenableBuilder<double>(
                                  valueListenable: state.decayProgress,
                                  builder: (context, decayValue, child) {
                                    return ComboDecayBadge(
                                      multiplier: multValue,
                                      decayProgress: decayValue,
                                    );
                                  },
                                );
                          // Shrink the 40px badge into a compact corner accent.
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: SizedBox(
                              width: 27.0,
                              height: 27.0,
                              child: FittedBox(child: badge),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // RIGHT — Forbidden shape thumbnail + AVOID label
                  ValueListenableBuilder(
                    valueListenable: state.forbiddenShape,
                    builder: (context, shapeType, child) {
                      if (shapeType == null) {
                        return const SizedBox(
                          width: AppSizes.kForbiddenThumbnailSize,
                          height: AppSizes.kForbiddenThumbnailSize,
                        );
                      }

                      final shapePainter = BaseShape.forType(shapeType);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ForbiddenPulse(
                            child: ProximityPulse(
                              trigger: state.proximityTrigger,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Dashed blue border
                                  SizedBox(
                                    width: AppSizes.kForbiddenThumbnailSize,
                                    height: AppSizes.kForbiddenThumbnailSize,
                                    child: CustomPaint(
                                      painter: DashedThumbnailBorderPainter(
                                        color: AppColors.kAccent,
                                      ),
                                    ),
                                  ),
                                  // Shape fill
                                  SizedBox(
                                    width:
                                        AppSizes.kForbiddenThumbnailSize - 12.0,
                                    height:
                                        AppSizes.kForbiddenThumbnailSize - 12.0,
                                    child: CustomPaint(
                                      painter: ShapeFillPainter(
                                        shape: shapePainter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // SizedBox(height: 2.0) REMOVED — caused 12px overflow on tall screens
                          const Text(
                            "AVOID",
                            style: TextStyle(
                              fontFamily: AppFonts.kFontBody,
                              fontSize: AppSizes.kForbiddenLabelFontSize,
                              color: AppColors.kAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Dividing line: 1 px Off White at 10% opacity (Section 4.4)
          Container(
            height: 1.0,
            width: double.infinity,
            // ignore: deprecated_member_use
            color: AppColors.kPrimaryText.withOpacity(0.10),
          ),
        ],
      ),
    );
  }
}

/// Simple painter to fill a shape white.
class ShapeFillPainter extends CustomPainter {
  final BaseShape shape;

  ShapeFillPainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.kPrimaryText
      ..style = PaintingStyle.fill;
    shape.paintShape(canvas, size, paint);
  }

  @override
  bool shouldRepaint(covariant ShapeFillPainter oldDelegate) =>
      // Each shape is its own BaseShape subclass, so a different forbidden shape
      // means a different runtimeType. Repaint when it changes — otherwise the
      // mid-round forbidden rotation leaves the old shape drawn in the HUD.
      oldDelegate.shape.runtimeType != shape.runtimeType;
}

/// Draws a dashed circle border around the forbidden shape thumbnail.
class DashedThumbnailBorderPainter extends CustomPainter {
  final Color color;

  DashedThumbnailBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Draw dashed circle outline
    const double circumference = 2 * 3.14159265;
    const double gap = 4.0;
    final int dashCount = (circumference * radius / (gap * 2)).round();
    final double angleStep = circumference / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        angleStep / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashedThumbnailBorderPainter oldDelegate) =>
      false;
}
