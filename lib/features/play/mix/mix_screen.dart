import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/matching/matching_content.dart';
import 'package:languagelearner/features/play/mix/mix_game.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/quiz/quiz_content.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/play/typing/typing_content.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The Mix mode: typing, choosing and matching tasks in random order.
///
/// The [MixGame] draws the steps; this screen shows the body of the mode of
/// the current step (the same widgets the single modes use) in the common
/// frame, with a short cross-fade between steps.
class MixScreen extends ConsumerStatefulWidget {
  const MixScreen({super.key});

  @override
  ConsumerState<MixScreen> createState() => _MixScreenState();
}

class _MixScreenState extends ConsumerState<MixScreen> {
  /// How long one step fades into the next.
  static const _fade = Duration(milliseconds: 200);

  MixGame? _game;
  late Deck _deck;
  var _finished = false;

  MixGame? _gameFor(Deck? deck) {
    if (_game == null && deck != null && deck.words.isNotEmpty) {
      _deck = deck;
      final settings = ref.read(settingsProvider);
      final random = ref.read(roundRandomProvider);
      final session = RoundSession(
        words: deck.words,
        promptLanguage: settings.promptLanguage,
        random: random,
        now: ref.read(clockProvider),
      );
      _game = MixGame(
        session: session,
        pairsPerPage: settings.pairsPerPage,
        random: random,
      )..addListener(_onChanged);
    }
    return _game;
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

  void _openSummary(MixGame game) {
    final i18n = context.i18n;
    final session = game.session;
    final result = game.result;
    // The words that were not right at the first attempt, in round order.
    final review = {...result.helpedWords, ...result.missedWords};
    final data = RoundSummaryData(
      modeName: PlayMode.mix.title(context),
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
      restartLabel: i18n.restartMix,
      restartLocation: AppRoutes.play(PlayMode.mix),
    );
    context.go(AppRoutes.summary(PlayMode.mix), extra: data);
  }

  @override
  void dispose() {
    _game?.dispose();
    super.dispose();
  }

  Widget _stepContent(MixGame game) => switch (game.stepType) {
    MixStepType.typing => TypingContent(game: game.typing!),
    MixStepType.quiz => QuizContent(game: game.quiz!),
    MixStepType.matching => MatchingContent(game: game.matching!),
    null => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(selectedDeckProvider).value;
    final game = _gameFor(deck);
    final title = PlayMode.mix.title(context);
    void goHome() => context.go(AppRoutes.home);

    if (game == null || game.isFinished) {
      return GameScaffold(
        title: title,
        counter: '',
        progress: game == null ? 0 : 1,
        onBack: goHome,
        child: const SizedBox.shrink(),
      );
    }

    // The words that are done, including the pairs of a matching step that
    // are already found.
    final solved = game.matching?.pairsFound ?? game.index;

    return GameScaffold(
      title: title,
      counter: '$solved / ${game.total}',
      progress: solved / game.total,
      onBack: goHome,
      child: AnimatedSwitcher(
        duration: _fade,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: KeyedSubtree(
          key: ValueKey(game.stepNumber),
          child: _stepContent(game),
        ),
      ),
    );
  }
}
