import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';

/// The color of the number in a [StatTile].
enum StatTone { neutral, success, error }

/// A big number with a caption below it, e.g. "5" / "correct first time".
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.tone = StatTone.neutral,
    super.key,
  });

  final String value;
  final String label;
  final StatTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final numberColor = switch (tone) {
      StatTone.neutral => c.text,
      StatTone.success => c.successNumber,
      StatTone.error => c.errorNumber,
    };
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: AppCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: headingFontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: numberColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 14,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
