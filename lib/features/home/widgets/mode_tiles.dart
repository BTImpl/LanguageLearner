import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/play_requirements.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

const _modeIcons = <PlayMode, IconData>{
  PlayMode.flashcards: Icons.filter_none,
  PlayMode.matching: Icons.account_tree_outlined,
  PlayMode.quiz: Icons.grid_view_outlined,
  PlayMode.typing: Icons.edit_outlined,
  PlayMode.mix: Icons.shuffle,
};

/// The wide Mix tile on top of the 2 x 2 grid of the other modes.
///
/// A mode the deck is too small for ([wordCount] words) is disabled and its
/// tile says how many words it needs.
class ModeTiles extends StatelessWidget {
  const ModeTiles({required this.wordCount, super.key});

  final int wordCount;

  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MixTile(wordCount: wordCount),
        const SizedBox(height: _gap),
        _row(PlayMode.flashcards, PlayMode.matching),
        const SizedBox(height: _gap),
        _row(PlayMode.quiz, PlayMode.typing),
      ],
    );
  }

  Widget _row(PlayMode left, PlayMode right) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ModeTile(mode: left, wordCount: wordCount),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: _ModeTile(mode: right, wordCount: wordCount),
        ),
      ],
    ),
  );
}

class _MixTile extends StatelessWidget {
  const _MixTile({required this.wordCount});

  final int wordCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const mode = PlayMode.mix;
    final needed = minWordsFor(mode);
    final enabled = wordCount >= needed;
    final hint = enabled ? mode.hint(context) : context.i18n.needsWords(needed);
    final textColor = enabled ? c.onPrimary : c.textMuted;
    return Semantics(
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: '${mode.title(context)}. $hint',
      child: Material(
        color: enabled ? c.primary : c.surfaceRaised,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.wideTile),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadii.wideTile,
          ),
          onTap: enabled ? () => context.go(AppRoutes.play(mode)) : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.title(context),
                        style: TextStyle(
                          fontFamily: headingFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(_modeIcons[mode], size: 32, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.wordCount});

  final PlayMode mode;
  final int wordCount;

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadii.tile,
    side: BorderSide(color: Colors.transparent),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final needed = minWordsFor(mode);
    final enabled = wordCount >= needed;
    final hint = enabled ? mode.hint(context) : context.i18n.needsWords(needed);
    return Semantics(
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: '${mode.title(context)}. $hint',
      child: Material(
        color: c.surface,
        shape: _shape.copyWith(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: _shape,
          onTap: enabled ? () => context.go(AppRoutes.play(mode)) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 122),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _modeIcons[mode],
                    size: 28,
                    color: enabled ? c.highlight : c.textMuted,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        mode.title(context),
                        style: TextStyle(
                          fontFamily: headingFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: enabled ? c.text : c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 13,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
