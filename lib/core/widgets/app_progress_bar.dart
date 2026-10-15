import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';

/// A rounded progress indicator, 6 px high unless [height] says otherwise.
///
/// [value] is between 0 and 1; values outside are clamped.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.height = defaultHeight,
    super.key,
  });

  static const double defaultHeight = 6;

  final double value;
  final double height;

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
