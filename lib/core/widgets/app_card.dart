import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';

/// A surface-colored card with a border and a configurable (usually
/// asymmetric) corner shape, see [AppRadii].
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.borderRadius = AppRadii.tile,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// Defaults to the surface color. Ignored when [gradient] is set.
  final Color? color;

  /// Used by the flashcard and the round-end header card only.
  final Gradient? gradient;

  /// Defaults to the line color.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? c.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
