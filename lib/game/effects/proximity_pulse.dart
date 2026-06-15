import 'package:flutter/material.dart';

/// ProximityPulse — single white flash on HUD thumbnail when tap lands within 80px of forbidden shape centre but hits another object, 0.12s (FR-15, Section 6.4)
class ProximityPulse extends StatefulWidget {
  final Widget child;
  final ValueNotifier<int> trigger;

  const ProximityPulse({
    super.key,
    required this.child,
    required this.trigger,
  });

  @override
  State<ProximityPulse> createState() => _ProximityPulseState();
}

class _ProximityPulseState extends State<ProximityPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    widget.trigger.addListener(_onTrigger);
  }

  void _onTrigger() {
    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_onTrigger);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double opacity = (1.0 - _controller.value).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            child!,
            if (_controller.isAnimating)
              IgnorePointer(
                child: Container(
                  width: 36, // Matches AppSizes.kForbiddenThumbnailSize
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(opacity * 0.7),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
