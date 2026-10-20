import 'dart:async';

import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/confirm_dialog.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Common frame of the game screens: back button, the mode name in the
/// middle, a counter (e.g. "7 / 12") on the right, a progress bar below, then
/// the [child] with the screen margin.
///
/// With [confirmLeave] the back button and the system back gesture first ask
/// whether to leave the round, because its result is not saved.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    required this.title,
    required this.counter,
    required this.progress,
    required this.child,
    this.action,
    this.onBack,
    this.confirmLeave = false,
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

  /// Whether leaving needs the student's confirmation: set it while a round
  /// has progress that would be lost.
  final bool confirmLeave;

  Future<void> _leave(BuildContext context) async {
    if (confirmLeave) {
      final leave = await _askToLeave(context);
      if (!leave || !context.mounted) {
        return;
      }
    }
    final back = onBack;
    if (back != null) {
      back();
    } else if (confirmLeave) {
      // `maybePop` would be stopped by the PopScope below.
      Navigator.of(context).pop();
    } else {
      unawaited(Navigator.maybePop(context));
    }
  }

  Future<bool> _askToLeave(BuildContext context) {
    final i18n = context.i18n;
    return showConfirmDialog(
      context,
      title: i18n.leaveRoundTitle,
      message: i18n.leaveRoundMessage,
      confirmLabel: i18n.leaveRoundConfirm,
      cancelLabel: i18n.leaveRoundCancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final back = IconSquareButton(
      icon: Icons.chevron_left,
      semanticLabel: context.i18n.back,
      onPressed: () => unawaited(_leave(context)),
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
    final scaffold = Scaffold(
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
    // Always wrapped, so the tree keeps its shape when [confirmLeave] changes
    // in the middle of a round (the screen below must not be rebuilt from
    // scratch after the first answer).
    return PopScope(
      canPop: !confirmLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_leave(context));
        }
      },
      child: scaffold,
    );
  }
}
