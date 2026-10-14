import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';

/// A 44 x 44 rounded square icon button (back, close, refresh).
///
/// [semanticLabel] is required: an icon alone says nothing to a screen reader.
/// It is also shown as the tooltip.
class IconSquareButton extends StatelessWidget {
  const IconSquareButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.backgroundColor,
    this.loading = false,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  /// Defaults to the surface color; pass the background color on a card.
  final Color? backgroundColor;

  /// Shows a progress indicator instead of the icon and disables the button.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton(
      onPressed: loading ? null : onPressed,
      tooltip: semanticLabel,
      icon: loading
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: c.text),
            )
          : Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSizes.touchTarget),
        minimumSize: const Size.square(AppSizes.touchTarget),
        padding: EdgeInsets.zero,
        // Material pads the tap target to 48; the design wants exactly 44.
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: backgroundColor ?? c.surface,
        foregroundColor: c.text,
        disabledForegroundColor: c.textMuted,
        side: BorderSide(color: c.line),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
      ),
    );
  }
}
