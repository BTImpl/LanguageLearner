import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';

/// The small btimpl logo with "btimpl.eu" at the bottom of the settings.
class BrandFooter extends StatelessWidget {
  const BrandFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/branding/icon-512.png',
              width: 36,
              height: 36,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'btimpl.eu',
          style: TextStyle(
            fontFamily: bodyFontFamily,
            fontSize: 16,
            color: c.textMuted,
          ),
        ),
      ],
    );
  }
}
