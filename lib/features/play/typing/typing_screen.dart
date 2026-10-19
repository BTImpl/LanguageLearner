import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/prompt_language_providers.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/play/typing/typing_content.dart';
import 'package:languagelearner/features/play/typing/typing_game.dart';
import 'package:languagelearner/features/stats/data/record_round.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The exact-match mode: a word is asked and the answer must be typed.
class TypingScreen extends ConsumerStatefulWidget {
  const TypingScreen({super.key});

  @override
  ConsumerState<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends ConsumerState<TypingScreen> {
  TypingGame? _game;
  late Deck _deck;
  var _finished = false;

  TypingGame? _gameFor(Deck? deck) {
    if (_game == null && deck != null && deck.words.isNotEmpty) {
      _deck = deck;
      final session = RoundSession(
        words: deck.words,
        promptLanguage: ref.read(effectivePromptLanguageProvider),
        random: ref.read(roundRandomProvider),
        now: ref.read(clockProvider),
      );
      _game = TypingGame(session: session)..addListener(_onChanged);
    }
    return _game;
  }

  /// Asks in the other language and starts the round again. The choice lasts
  /// until the player returns to the menu.
  void _switchLanguage() {
    final language = ref.read(effectivePromptLanguageProvider);
    ref.read(promptLanguageOverrideProvider.notifier).choose(language.flipped);
    _game?.dispose();
    setState(() => _game = null);
  }

  void _onChanged() {
    if (!mounted) {
      return;
    }
    final game = _game!;
    if (game.isFinished) {
      if (!_finished) {
        _finished = true;
        _openSummary(game);
      }
      return;
    }
    setState(() {});
  }

  void _openSummary(TypingGame game) {
    final i18n = context.i18n;
    final session = game.session;
    final result = game.result;
    recordRound(ref, result: result, deckId: _deck.id, mode: PlayMode.typing);
    // The words that were not right at the first attempt, in round order.
    final review = {...result.helpedWords, ...result.missedWords};
    final data = RoundSummaryData(
      modeName: PlayMode.typing.title(context),
      deckName: _deck.name,
      headline: i18n.firstTryHeadline(result.total, result.firstTry),
      stats: [
        SummaryStat(
          value: '${result.firstTry}',
          label: i18n.statCorrectFirst,
          tone: StatTone.success,
        ),
        SummaryStat(value: '${result.withHelp}', label: i18n.statWithHelp),
        SummaryStat(
          value: '${result.wrongFirst}',
          label: i18n.statWrongFirst,
          tone: StatTone.error,
        ),
      ],
      reviewWords: [
        for (final word in session.words)
          if (review.contains(word))
            ReviewWord(
              prompt: session.promptText(word),
              answer: session.answerText(word),
            ),
      ],
      restartLabel: i18n.restartTyping,
      restartLocation: AppRoutes.play(PlayMode.typing),
    );
    context.go(AppRoutes.summary(PlayMode.typing), extra: data);
  }

  @override
  void dispose() {
    _game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(selectedDeckProvider).value;
    final game = _gameFor(deck);
    final title = PlayMode.typing.title(context);
    void goHome() => context.go(AppRoutes.home);

    if (game == null || game.current == null) {
      return GameScaffold(
        title: title,
        counter: '',
        progress: game == null ? 0 : 1,
        onBack: goHome,
        child: const SizedBox.shrink(),
      );
    }

    return GameScaffold(
      title: title,
      counter: '${game.index + 1} / ${game.total}',
      progress: (game.index + 1) / game.total,
      onBack: goHome,
      confirmLeave: game.index > 0,
      action: IconSquareButton(
        icon: Icons.swap_horiz,
        semanticLabel: context.i18n.switchQuestionLanguage,
        onPressed: _switchLanguage,
      ),
      // A new game gets a new input: empty, without error and help.
      child: TypingContent(key: ObjectKey(game), game: game),
    );
  }
}
