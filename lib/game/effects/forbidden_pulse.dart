import 'dart:math';
import 'package:flutter/material.dart';

/// ForbiddenPulse — HUD thumbnail opacity 0.6→1.0 sine loop, 1s cycle (Section 6.4)
class ForbiddenPulse extends StatefulWidget {
  final Widget child;

  const ForbiddenPulse({super.key, required this.child});

  @override
  State<ForbiddenPulse> createState() => _ForbiddenPulseState();
}

class _ForbiddenPulseState extends State<ForbiddenPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sine wave oscillation: sin(2 * pi * t) oscillates from -1 to 1.
        final double sineValue = sin(2 * pi * _controller.value);
        // Map -1 to 1 range to 0.6 to 1.0 range:
        final double opacity = 0.8 + 0.2 * sineValue;

        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
