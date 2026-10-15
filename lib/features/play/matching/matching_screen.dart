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
import 'package:languagelearner/features/play/matching/matching_game.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/stats/data/record_round.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

export 'package:languagelearner/features/play/matching/matching_content.dart'
    show matchTileKey;

/// The matching mode: two columns of tiles to pair up, page after page.
class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  MatchingGame? _game;
  late Deck _deck;
  var _finished = false;

  MatchingGame? _gameFor(Deck? deck) {
    if (_game == null && deck != null && deck.words.isNotEmpty) {
      _deck = deck;
      final random = ref.read(roundRandomProvider);
      final session = RoundSession(
        words: deck.words,
        promptLanguage: ref.read(settingsProvider).promptLanguage,
        random: random,
        now: ref.read(clockProvider),
      );
      _game = MatchingGame(
        session: session,
        pairsPerPage: ref.read(settingsProvider).pairsPerPage,
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

  void _openSummary(MatchingGame game) {
    final i18n = context.i18n;
    final session = game.session;
    final result = game.result;
    recordRound(ref, result: result, deckId: _deck.id, mode: PlayMode.matching);
    final data = RoundSummaryData(
      modeName: PlayMode.matching.title(context),
      deckName: _deck.name,
      headline: i18n.matchingHeadline(result.total),
      stats: [
        SummaryStat(
          value: '${result.firstTry}',
          label: i18n.statFirstTry,
          tone: StatTone.success,
        ),
        SummaryStat(
          value: '${result.extra(RoundCounters.wrongPairs)}',
          label: i18n.statWrongTries,
          tone: StatTone.error,
        ),
        SummaryStat(
          value: '${result.extra(RoundCounters.pages)}',
          label: i18n.statPages,
        ),
      ],
      reviewWords: [
        for (final word in result.missedWords)
          ReviewWord(
            prompt: session.promptText(word),
            answer: session.answerText(word),
          ),
      ],
      restartLabel: i18n.restartMatching,
      restartLocation: AppRoutes.play(PlayMode.matching),
    );
    context.go(AppRoutes.summary(PlayMode.matching), extra: data);
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
    final title = PlayMode.matching.title(context);
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

    final i18n = context.i18n;
    final total = game.session.total;
    final found = game.pairsFound;
    final wrongTries = game.result.extra(RoundCounters.wrongPairs);

    return GameScaffold(
      title: title,
      counter: i18n.matchingPageCounter(game.pageIndex + 1, game.pageCount),
      progress: found / total,
      onBack: goHome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: MatchingContent(game: game)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '$found / $total',
                  label: i18n.statPairsFound,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: '$wrongTries',
                  label: i18n.statWrongTries,
                  tone: wrongTries > 0 ? StatTone.error : StatTone.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
