import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../game/config/game_constants.dart';

/// ComboDecayArc — 3px arc drains over the idle decay interval, turns amber and pulses at ≤20% remaining, resets on correct tap (FR-16, Section 6.4)
class ComboDecayArc extends StatefulWidget {
  final double decayProgress;
  final double size;

  const ComboDecayArc({
    super.key,
    required this.decayProgress,
    required this.size,
  });

  @override
  State<ComboDecayArc> createState() => _ComboDecayArcState();
}

class _ComboDecayArcState extends State<ComboDecayArc> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWarning = widget.decayProgress <= GameConstants.kComboDecayWarningPercent;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulseValue = _pulseController.value;
        // Pulse stroke width slightly and fade opacity if in warning range
        final double strokeWidth = isWarning ? 3.0 + (pulseValue * 1.5) : 3.0;
        final Color color = isWarning
            // ignore: deprecated_member_use
            ? AppColors.kDecayWarning.withOpacity(0.5 + (0.5 * pulseValue))
            : AppColors.kAccent;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ComboDecayArcPainter(
              decayProgress: widget.decayProgress,
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _ComboDecayArcPainter extends CustomPainter {
  final double decayProgress;
  final Color color;
  final double strokeWidth;

  _ComboDecayArcPainter({
    required this.decayProgress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * pi * decayProgress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ComboDecayArcPainter oldDelegate) {
    return oldDelegate.decayProgress != decayProgress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
