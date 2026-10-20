import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The state of a [ChoiceTile].
enum ChoiceState { idle, selected, correct, wrong }

/// An answer or pair tile.
///
/// The state is shown by color and also by an icon (check / X), so it does not
/// depend on color alone; screen readers get it as part of the label.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    required this.label,
    this.state = ChoiceState.idle,
    this.onTap,
    this.reserveIconSpace = false,
    super.key,
  });

  static const double _iconSize = 24;

  /// Key of the tile's surface, for tests.
  static const Key surfaceKey = Key('choice-tile-surface');

  final String label;
  final ChoiceState state;

  /// `null` makes the tile non-interactive (e.g. already matched).
  final VoidCallback? onTap;

  /// Keeps the room of the state icon even while there is none, so the text
  /// wraps the same way in every state and the tile does not change its height
  /// when it turns green or red.
  final bool reserveIconSpace;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (background, border, foreground, icon) = switch (state) {
      ChoiceState.idle => (c.surface, c.line, c.text, null),
      ChoiceState.selected => (c.surfaceRaised, c.highlight, c.text, null),
      ChoiceState.correct => (
        c.successBackground,
        c.successBorder,
        c.successText,
        Icons.check,
      ),
      ChoiceState.wrong => (
        c.errorBackground,
        c.errorBorder,
        c.errorText,
        Icons.close,
      ),
    };
    final i18n = context.i18n;
    final semanticLabel = switch (state) {
      ChoiceState.correct => i18n.choiceCorrect(label),
      ChoiceState.wrong => i18n.choiceWrong(label),
      _ => label,
    };

    return Semantics(
      button: true,
      selected: state == ChoiceState.selected,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        key: surfaceKey,
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.choice,
          side: BorderSide(
            color: border,
            width: state == ChoiceState.idle ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadii.choice,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, color: foreground)
                  else if (reserveIconSpace)
                    const SizedBox(width: _iconSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
