import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/matching/match_tile.dart';
import 'package:languagelearner/features/play/matching/matching_game.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the live tile of [word] in the column [side], for tests.
Key matchTileKey(WordPair word, MatchSide side) =>
    Key('match-tile-${side.name}-${word.id}');

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

  // The tiles of the page in the order they were laid out. A pair that is gone
  // leaves its place empty, so the other tiles do not move.
  var _slotPage = -1;
  var _englishSlots = <WordPair>[];
  var _hungarianSlots = <WordPair>[];

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

  void _onTap(MatchingGame game, WordPair word, MatchSide side) {
    game.tap(word, side);
    switch (game.tile(word, side)?.state) {
      case TileState.matched:
        HapticFeedback.lightImpact().ignore();
      case TileState.wrong:
        HapticFeedback.heavyImpact().ignore();
      case _:
        break;
    }
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

    if (_slotPage != game.pageIndex) {
      _slotPage = game.pageIndex;
      _englishSlots = [for (final t in game.englishTiles) t.word];
      _hungarianSlots = [for (final t in game.hungarianTiles) t.word];
    }

    final i18n = context.i18n;
    final c = context.colors;
    final total = game.session.total;
    final waiting = game.englishTiles
        .where((tile) => tile.state != TileState.matched)
        .length;
    final found = game.session.index + _englishSlots.length - waiting;
    final wrongTries = game.result.extra(RoundCounters.wrongPairs);

    return GameScaffold(
      title: title,
      counter: i18n.matchingPageCounter(game.pageIndex + 1, game.pageCount),
      progress: found / total,
      onBack: goHome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            PlayMode.matching.hint(context),
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < _englishSlots.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _slot(
                            game,
                            _englishSlots[i],
                            MatchSide.english,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _slot(
                            game,
                            _hungarianSlots[i],
                            MatchSide.hungarian,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
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

  Widget _slot(MatchingGame game, WordPair word, MatchSide side) {
    final tile = game.tile(word, side);
    final label = switch (side) {
      MatchSide.english => word.english,
      MatchSide.hungarian => word.hungarian,
    };
    if (tile == null) {
      return _GoneTile(label: label);
    }
    final state = switch (tile.state) {
      TileState.idle => ChoiceState.idle,
      TileState.selected => ChoiceState.selected,
      TileState.matched => ChoiceState.correct,
      TileState.wrong => ChoiceState.wrong,
    };
    final canTap =
        tile.state == TileState.idle || tile.state == TileState.selected;
    return AnimatedOpacity(
      // A found pair fades out in the time it stays on the screen.
      opacity: tile.state == TileState.matched ? 0 : 1,
      curve: Curves.easeIn,
      duration: game.matchedDelay,
      child: ChoiceTile(
        key: matchTileKey(word, side),
        label: label,
        state: state,
        onTap: canTap ? () => _onTap(game, word, side) : null,
      ),
    );
  }
}

/// The empty place of a pair that is gone. It is as high as the tile was, so
/// the tiles around it stay where they are.
class _GoneTile extends StatelessWidget {
  const _GoneTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
