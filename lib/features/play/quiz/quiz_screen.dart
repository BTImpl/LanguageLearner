import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/quiz/quiz_content.dart';
import 'package:languagelearner/features/play/quiz/quiz_game.dart';
import 'package:languagelearner/features/play/round/prompt_language_providers.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/stats/data/record_round.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The quiz mode: a word and four answers, until every word is known.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizGame? _game;
  late Deck _deck;
  var _finished = false;

  QuizGame? _gameFor(Deck? deck) {
    if (_game == null && deck != null && deck.words.isNotEmpty) {
      _deck = deck;
      final random = ref.read(roundRandomProvider);
      final session = RoundSession(
        words: deck.words,
        promptLanguage: ref.read(effectivePromptLanguageProvider),
        random: random,
        now: ref.read(clockProvider),
      );
      _game = QuizGame(session: session, random: random)
        ..addListener(_onChanged);
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

  void _openSummary(QuizGame game) {
    final i18n = context.i18n;
    final session = game.session;
    final result = game.result;
    recordRound(ref, result: result, deckId: _deck.id, mode: PlayMode.quiz);
    final data = RoundSummaryData(
      modeName: PlayMode.quiz.title(context),
      deckName: _deck.name,
      headline: i18n.firstTryHeadline(result.total, result.firstTry),
      stats: [
        SummaryStat(
          value: '${result.firstTry}',
          label: i18n.statGuessed,
          tone: StatTone.success,
        ),
        SummaryStat(
          value: '${result.wrongFirst}',
          label: i18n.statWrongFirst,
          tone: StatTone.error,
        ),
      ],
      reviewWords: [
        for (final word in result.missedWords)
          ReviewWord(
            prompt: session.promptText(word),
            answer: session.answerText(word),
          ),
      ],
      restartLabel: i18n.restartQuiz,
      restartLocation: AppRoutes.play(PlayMode.quiz),
    );
    context.go(AppRoutes.summary(PlayMode.quiz), extra: data);
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
    final title = PlayMode.quiz.title(context);
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
    if (!game.isPlayable) {
      return GameScaffold(
        title: title,
        counter: '',
        progress: 0,
        onBack: goHome,
        child: _TooFewWords(onHome: goHome),
      );
    }

    final i18n = context.i18n;
    final wrongFirst = game.wrongFirstCount;

    return GameScaffold(
      title: title,
      counter: '${game.index + 1} / ${game.total}',
      progress: (game.index + 1) / game.total,
      onBack: goHome,
      action: IconSquareButton(
        icon: Icons.swap_horiz,
        semanticLabel: i18n.switchQuestionLanguage,
        onPressed: _switchLanguage,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: QuizContent(key: ObjectKey(game), game: game),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${game.firstTryCount}',
                  label: i18n.statGuessed,
                  tone: StatTone.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: '$wrongFirst',
                  label: i18n.statWrongFirst,
                  tone: wrongFirst > 0 ? StatTone.error : StatTone.neutral,
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

/// Shown instead of the game when the deck is too small.
class _TooFewWords extends StatelessWidget {
  const _TooFewWords({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Text(
              i18n.quizNeedsWords,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: headingFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
        ),
        PrimaryButton(label: i18n.backToHome, onPressed: onHome),
        const SizedBox(height: 20),
      ],
    );
  }
}
