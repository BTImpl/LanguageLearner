import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/speaking/speaking_content.dart';
import 'package:languagelearner/features/play/speaking/speaking_game.dart';
import 'package:languagelearner/features/play/speaking/speech_engine.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/stats/data/record_round.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The speaking mode: a Hungarian word is shown and the English one must be
/// said aloud.
///
/// The recogniser knows English only, so the word is always asked in
/// Hungarian, whatever the default language of the questions is.
class SpeakingScreen extends ConsumerStatefulWidget {
  const SpeakingScreen({super.key});

  @override
  ConsumerState<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends ConsumerState<SpeakingScreen> {
  SpeakingGame? _game;
  late Deck _deck;
  var _finished = false;
  var _wasDenied = false;

  SpeakingGame? _gameFor(Deck? deck) {
    if (_game == null && deck != null && deck.words.isNotEmpty) {
      _deck = deck;
      final settings = ref.read(settingsProvider);
      final session = RoundSession(
        words: deck.words,
        promptLanguage: PromptLanguage.hungarian,
        random: ref.read(roundRandomProvider),
        now: ref.read(clockProvider),
      );
      _game = SpeakingGame(
        session: session,
        engine: ref.read(speechEngineProvider),
        hints: settings.speakingHints ? speakingHintsOf(deck) : const [],
        maxAttempts: settings.typingAttempts,
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
    // The Mix mode reads the status from the provider: refresh it when the
    // student said no, so the Mix stops drawing speaking tasks.
    final denied = game.feedback == SpeakingFeedback.denied;
    if (denied && !_wasDenied) {
      ref.invalidate(speechStatusProvider);
    }
    _wasDenied = denied;
    setState(() {});
  }

  void _openSummary(SpeakingGame game) {
    final i18n = context.i18n;
    final session = game.session;
    final result = game.result;
    recordRound(ref, result: result, deckId: _deck.id, mode: PlayMode.speaking);
    // The words that were not right at the first attempt, in round order.
    final review = {...result.helpedWords, ...result.missedWords};
    final data = RoundSummaryData(
      modeName: PlayMode.speaking.title(context),
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
      restartLabel: i18n.restartSpeaking,
      restartLocation: AppRoutes.play(PlayMode.speaking),
    );
    context.go(AppRoutes.summary(PlayMode.speaking), extra: data);
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
    final title = PlayMode.speaking.title(context);
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
      child: SpeakingContent(game: game),
    );
  }
}
