import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';

const TextStyle _buttonTextStyle = TextStyle(
  fontFamily: bodyFontFamily,
  fontSize: 17,
  fontWeight: FontWeight.w700,
);

/// Full-width main action button: primary color, dark text, optional icon.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
      disabledBackgroundColor: c.surfaceRaised,
      disabledForegroundColor: c.textMuted,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
      textStyle: _buttonTextStyle,
    );
    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Full-width secondary action button: surface color with a 1 px border.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
      backgroundColor: c.surface,
      foregroundColor: c.text,
      disabledForegroundColor: c.textMuted,
      side: BorderSide(color: c.line),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
      textStyle: _buttonTextStyle,
    );
    if (icon == null) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
