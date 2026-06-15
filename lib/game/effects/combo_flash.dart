import 'package:flutter/material.dart';

/// ComboFlash — combo badge scales 80→100% and settles on combo increase (Section 6.4)
class ComboFlash extends StatefulWidget {
  final Widget child;
  final int multiplier;

  const ComboFlash({
    super.key,
    required this.child,
    required this.multiplier,
  });

  @override
  State<ComboFlash> createState() => _ComboFlashState();
}

class _ComboFlashState extends State<ComboFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant ComboFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.multiplier > oldWidget.multiplier) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
