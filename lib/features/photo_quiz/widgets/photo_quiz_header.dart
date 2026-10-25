import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The top row of the photo-quiz screens: a back button and the title in the
/// middle (the empty space on the right keeps the title centered).
class PhotoQuizHeader extends StatelessWidget {
  const PhotoQuizHeader({
    required this.title,
    required this.onBack,
    this.closeIcon = false,
    this.action,
    super.key,
  });

  final String title;
  final VoidCallback onBack;

  /// A cross instead of the back arrow, for the screens that end the flow.
  final bool closeIcon;

  /// A 44 x 44 button on the right (e.g. an [IconSquareButton]).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconSquareButton(
          icon: closeIcon ? Icons.close : Icons.chevron_left,
          semanticLabel: context.i18n.back,
          onPressed: onBack,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: bodyFontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.colors.text,
            ),
          ),
        ),
        action ?? const SizedBox(width: 44),
      ],
    );
  }
}
