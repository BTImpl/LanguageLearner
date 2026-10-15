import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/quiz/quiz_game.dart';
import 'package:languagelearner/features/play/quiz/quiz_option.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
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
        promptLanguage: ref.read(settingsProvider).promptLanguage,
        random: random,
        now: ref.read(clockProvider),
      );
      _game = QuizGame(session: session, random: random)
        ..addListener(_onChanged);
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

  void _openSummary(QuizGame game) {
    final i18n = context.i18n;
    final session = game.session;
    final result = game.result;
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

  void _readAloud(WordPair word) {
    ref.read(ttsServiceProvider).speak(word.english).ignore();
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
    final word = game.current!;
    final session = game.session;
    final options = game.options;
    final answered = options.any((o) => o.state == QuizOptionState.correct);
    final hasWrong = options.any((o) => o.state == QuizOptionState.wrong);
    final wrongFirst = game.wrongFirstCount;

    return GameScaffold(
      title: title,
      counter: '${game.index + 1} / ${game.total}',
      progress: (game.index + 1) / game.total,
      onBack: goHome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuestionCard(
                    label: session.promptIsEnglish
                        ? i18n.quizQuestionToHungarian
                        : i18n.quizQuestionToEnglish,
                    text: session.promptText(word),
                    onReadAloud: session.promptIsEnglish
                        ? () => _readAloud(word)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _optionTile(game, options[i], locked: answered),
                  ],
                  const SizedBox(height: 12),
                  _TryAgainHint(visible: hasWrong && !answered),
                ],
              ),
            ),
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

  Widget _optionTile(QuizGame game, QuizOption option, {required bool locked}) {
    final state = switch (option.state) {
      QuizOptionState.idle => ChoiceState.idle,
      QuizOptionState.wrong => ChoiceState.wrong,
      QuizOptionState.correct => ChoiceState.correct,
    };
    final canTap = option.state == QuizOptionState.idle && !locked;
    return ChoiceTile(
      key: quizOptionKey(option.word),
      label: option.text,
      state: state,
      onTap: canTap ? () => game.choose(option.word) : null,
    );
  }
}

/// The key of the answer tile that comes from [word], for tests.
Key quizOptionKey(WordPair word) => Key('quiz-option-${word.id}');

/// "Not this one" under the answers. It always takes its place, so the
/// answers do not jump when it appears.
class _TryAgainHint extends StatelessWidget {
  const _TryAgainHint({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 24,
      child: visible
          ? Semantics(
              liveRegion: true,
              child: Text(
                context.i18n.quizTryAgain,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.errorText,
                ),
              ),
            )
          : null,
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
