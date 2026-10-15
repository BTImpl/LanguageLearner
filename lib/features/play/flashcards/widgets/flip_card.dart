import 'dart:math';

import 'package:flutter/material.dart';

/// A card that turns around the vertical axis between [front] and [back].
///
/// The side is chosen with [showBack]; when it changes the card turns (in
/// [duration], or at once when the system asks for reduced motion).
class FlipCard extends StatefulWidget {
  const FlipCard({
    required this.showBack,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 450),
    super.key,
  });

  final bool showBack;
  final Widget front;
  final Widget back;
  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.showBack ? 1 : 0,
  );

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBack == widget.showBack) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.showBack ? 1 : 0;
    } else if (widget.showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
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
      builder: (context, _) {
        final angle = Curves.easeInOut.transform(_controller.value) * pi;
        final facingFront = angle < pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          // The back is turned by half a turn so it is not mirrored.
          child: facingFront
              ? widget.front
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: widget.back,
                ),
        );
      },
    );
  }
}
