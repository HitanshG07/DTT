import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';
import '../game/game_controller.dart';
import '../game/shapes/base_shape.dart';
import 'combo_decay_badge.dart';

/// HUD Overlay widget (S-06) showing lives, score, combo badge, and forbidden shape thumbnail.
///
/// Reference: Section 4.4, Section 11.4.
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
                  // LEFT — Lives
                  ValueListenableBuilder<int>(
                    valueListenable: state.lives,
                    builder: (context, livesValue, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final isActive = index < livesValue;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < 2 ? AppSizes.kHeartSpacing : 0.0,
                            ),
                            child: Icon(
                              Icons.favorite,
                              size: AppSizes.kHeartIconSize,
                              color: isActive
                                  ? AppColors.kWrong // Active: Red/Wrong
                                  : AppColors.kSecondaryText, // Lost: Mid Grey
                            ),
                          );
                        }),
                      );
                    },
                  ),

                  // CENTRE — Score + Combo Badge
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
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
                      ValueListenableBuilder<int>(
                        valueListenable: state.multiplier,
                        builder: (context, multValue, child) {
                          if (multValue <= 1) {
                            return const SizedBox.shrink();
                          }
                          return ValueListenableBuilder<double>(
                            valueListenable: state.decayProgress,
                            builder: (context, decayValue, child) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: ComboDecayBadge(
                                  multiplier: multValue,
                                  decayProgress: decayValue,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  // RIGHT — Forbidden shape thumbnail
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
                          Stack(
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
                                width: AppSizes.kForbiddenThumbnailSize - 12.0,
                                height: AppSizes.kForbiddenThumbnailSize - 12.0,
                                child: CustomPaint(
                                  painter: ShapeFillPainter(shape: shapePainter),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  bool shouldRepaint(covariant DashedThumbnailBorderPainter oldDelegate) => false;
}
