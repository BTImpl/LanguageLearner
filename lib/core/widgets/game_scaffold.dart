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
    this.onBack,
    super.key,
  });

  final String title;
  final String counter;

  /// Between 0 and 1.
  final double progress;
  final Widget child;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
              Row(
                children: [
                  IconSquareButton(
                    icon: Icons.chevron_left,
                    semanticLabel: context.i18n.back,
                    onPressed: onBack ?? () => Navigator.maybePop(context),
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
                        color: c.text,
                      ),
                    ),
                  ),
                  ConstrainedBox(
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
                  ),
                ],
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
