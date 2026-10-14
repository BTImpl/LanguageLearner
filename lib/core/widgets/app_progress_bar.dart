import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';

/// A 6 px high rounded progress indicator.
///
/// [value] is between 0 and 1; values outside are clamped.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({required this.value, super.key});

  static const double height = 6;

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final factor = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(factor * 100).round()}%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: ColoredBox(
              color: c.line,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 200),
                  widthFactor: factor,
                  heightFactor: 1,
                  child: ColoredBox(color: c.accent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
