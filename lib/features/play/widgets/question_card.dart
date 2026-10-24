import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The word that is asked, with a label above it and an optional read-aloud
/// button. Shared by the quiz and the exact-match game.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.label,
    required this.text,
    required this.onReadAloud,
    this.fontSize,
    super.key,
  });

  final String label;
  final String text;

  /// `null` hides the read-aloud button (the question is not English).
  final VoidCallback? onReadAloud;

  /// Replaces the size that follows from the length of the [text], for texts
  /// that are sentences and not single words.
  final double? fontSize;

  /// Long words get a smaller type so they do not break in the middle.
  double get _fontSize =>
      fontSize ??
      switch (text.length) {
        <= 10 => 52,
        <= 16 => 40,
        _ => 30,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      borderRadius: AppRadii.highlighted,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: bodyFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ),
              if (onReadAloud != null) ...[
                const SizedBox(width: 12),
                ReadAloudButton(onPressed: onReadAloud!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: c.text,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// The round read-aloud button, 48 x 48.
class ReadAloudButton extends StatelessWidget {
  const ReadAloudButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: context.i18n.readAloud,
      child: Material(
        color: c.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 48,
            child: Icon(Icons.volume_up, color: c.onPrimary),
          ),
        ),
      ),
    );
  }
}
