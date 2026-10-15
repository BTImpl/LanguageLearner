import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// One side of a flashcard. The English side has the brand gradient and a
/// read-aloud button ([onReadAloud]); the Hungarian side is a plain surface
/// without one.
class FlashcardFace extends StatelessWidget {
  const FlashcardFace({
    required this.language,
    required this.text,
    this.onReadAloud,
    super.key,
  });

  final PromptLanguage language;
  final String text;

  /// Only used on the English side.
  final VoidCallback? onReadAloud;

  bool get _isEnglish => language == PromptLanguage.english;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final textColor = _isEnglish ? c.onBrandGradient : c.text;
    final mutedColor = _isEnglish ? c.onBrandGradient : c.textMuted;
    return SizedBox.expand(
      child: AppCard(
        borderRadius: AppRadii.flip,
        gradient: _isEnglish ? c.brandGradient : null,
        borderColor: _isEnglish ? Colors.transparent : null,
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEnglish ? i18n.languageEnglish : i18n.languageHungarian,
                  style: TextStyle(
                    fontFamily: bodyFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: headingFontFamily,
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  _isEnglish ? i18n.flipHintHungarian : i18n.flipHintEnglish,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: bodyFontFamily,
                    fontSize: 14,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
            if (_isEnglish && onReadAloud != null)
              Positioned(
                top: 0,
                right: 0,
                child: Tooltip(
                  message: i18n.readAloud,
                  child: Material(
                    color: c.onBrandGradient,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onReadAloud,
                      child: const SizedBox.square(
                        dimension: 52,
                        child: Icon(Icons.volume_up, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
