import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Common frame of the game screens: back button, the mode name in the
/// middle, a counter (e.g. "7 / 12") on the right, a progress bar below, then
/// the [child] with the screen margin.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    required this.title,
    required this.counter,
    required this.progress,
    required this.child,
    this.action,
    this.onBack,
    super.key,
  });

  final String title;
  final String counter;

  /// Between 0 and 1.
  final double progress;
  final Widget child;

  /// An optional button before the counter. With it the title stays centered
  /// on the screen and gets at most 40% of the width.
  final Widget? action;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final back = IconSquareButton(
      icon: Icons.chevron_left,
      semanticLabel: context.i18n.back,
      onPressed: onBack ?? () => Navigator.maybePop(context),
    );
    final titleText = Text(
      title,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: c.text,
      ),
    );
    final counterText = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44),
      child: Text(
        counter,
        textAlign: TextAlign.end,
        style: TextStyle(
          fontFamily: bodyFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: c.textMuted,
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              if (action == null)
                Row(
                  children: [
                    back,
                    Expanded(child: titleText),
                    counterText,
                  ],
                )
              else
                LayoutBuilder(
                  builder: (context, box) => Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: back,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: box.maxWidth * 0.4,
                        ),
                        child: titleText,
                      ),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              action!,
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: counterText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              AppProgressBar(value: progress),
              const SizedBox(height: 20),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
