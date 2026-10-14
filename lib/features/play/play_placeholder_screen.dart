import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Empty game screen showing only the frame; each mode replaces it with its
/// real screen in the game-mode cards (LL-15, LL-17, ...). With [summary] it
/// stands for the round-end screen (LL-14).
class PlayPlaceholderScreen extends StatelessWidget {
  const PlayPlaceholderScreen({
    required this.mode,
    this.summary = false,
    super.key,
  });

  final PlayMode mode;
  final bool summary;

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: summary ? context.i18n.roundEnd : mode.title(context),
      counter: '',
      progress: 0,
      onBack: () => context.go(AppRoutes.home),
      child: const SizedBox.shrink(),
    );
  }
}
