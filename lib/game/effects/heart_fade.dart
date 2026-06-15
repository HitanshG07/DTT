import 'package:flutter/material.dart';

/// HeartFade — heart white→grey via AnimatedSwitcher, 0.4s (Section 6.4)
class HeartFade extends StatelessWidget {
  final bool isActive;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const HeartFade({
    super.key,
    required this.isActive,
    required this.size,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: Icon(
        Icons.favorite,
        key: ValueKey<bool>(isActive),
        size: size,
        color: isActive ? activeColor : inactiveColor,
      ),
    );
  }
}
