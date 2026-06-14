import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../game/config/shape_type.dart';
import '../game/shapes/base_shape.dart';

/// How to Play Screen (S-03) shown on first launch.
///
/// Reference: Section 5.1 S-03, Section 5.2.
class HowToPlayScreen extends StatelessWidget {
  final SharedPreferences prefs;

  const HowToPlayScreen({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final circleShape = BaseShape.forType(ShapeType.circle);

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Heading
              const Text(
                "HOW TO PLAY",
                style: TextStyle(
                  fontFamily: AppFonts.kFontDisplay,
                  fontSize: 28.0,
                  color: AppColors.kPrimaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Explanation body text
              const Text(
                "Shapes will fall from the top of the screen.\n\n"
                "One shape is FORBIDDEN each round — shown before you start.\n\n"
                "Tap everything except the forbidden shape.\n\n"
                "Tap the forbidden shape and you lose a life.\n\n"
                "You have 3 lives. When they run out, the round ends.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.kFontBody,
                  fontSize: 16.0,
                  color: AppColors.kSecondaryText,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              // Forbidden Shape Preview with Dashed Border
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dashed border container
                      SizedBox(
                        width: 100.0,
                        height: 100.0,
                        child: CustomPaint(
                          painter: DashedBorderPainter(color: AppColors.kAccent),
                        ),
                      ),
                      // Shape painter
                      SizedBox(
                        width: 60.0,
                        height: 60.0,
                        child: CustomPaint(
                          painter: ShapePainter(shape: circleShape),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                    "DON'T TAP THIS",
                    style: TextStyle(
                      fontFamily: AppFonts.kFontBody,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    // MOCK: shape is circle for illustration only
                    "// MOCK: shape is circle for illustration only in Stage 2",
                    style: TextStyle(
                      fontFamily: AppFonts.kFontBody,
                      fontSize: 10.0,
                      color: Colors.transparent,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Got It Button
              SizedBox(
                width: double.infinity,
                height: 56.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kAccent,
                    foregroundColor: AppColors.kPrimaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // 1. Write first launch flag false
                    await prefs.setBool('dtt_first_launch', false);
                    if (context.mounted) {
                      // 2. Navigate to start screen
                      Navigator.pushReplacementNamed(context, '/start');
                    }
                  },
                  child: const Text(
                    "GOT IT",
                    style: TextStyle(
                      fontFamily: AppFonts.kFontDisplay,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple CustomPainter that draws a given BaseShape with default white color.
class ShapePainter extends CustomPainter {
  final BaseShape shape;

  ShapePainter({required this.shape});

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

/// Draws a dashed circle outline border.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    const double circumference = 2 * pi;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
