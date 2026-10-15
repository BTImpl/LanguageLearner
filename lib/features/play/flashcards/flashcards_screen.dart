import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/play/flashcards/widgets/flashcard_face.dart';
import 'package:languagelearner/features/play/flashcards/widgets/flip_card.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_providers.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/round_session.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The flashcards mode: a flippable card per word, with read-aloud on the
/// English side, and previous / next navigation.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  static const _swipeVelocity = 300.0;

  RoundSession? _session;

  /// Whether the card shows the side that is not the start side.
  var _flipped = false;

  RoundSession? _sessionFor(Deck? deck) {
    if (_session == null && deck != null) {
      _session = RoundSession(
        words: deck.words,
        promptLanguage: ref.read(settingsProvider).promptLanguage,
        random: ref.read(roundRandomProvider),
        now: ref.read(clockProvider),
      );
    }
    return _session;
  }

  void _goTo(void Function() move) {
    setState(() {
      move();
      _flipped = false;
    });
  }

  void _readAloud(RoundSession session, WordPair word) {
    session.count(RoundCounters.readAloud);
    ref.read(ttsServiceProvider).speak(word.english).ignore();
  }

  void _finish(RoundSession session, Deck deck) {
    session.advance();
    final result = session.result;
    final i18n = context.i18n;
    final data = RoundSummaryData(
      modeName: PlayMode.flashcards.title(context),
      deckName: deck.name,
      headline: i18n.cardsViewedHeadline(result.total),
      stats: [
        SummaryStat(value: '${result.total}', label: i18n.statCards),
        SummaryStat(
          value: '${result.extra(RoundCounters.readAloud)}',
          label: i18n.statReadAloud,
        ),
        SummaryStat(value: '${result.minutes}', label: i18n.statMinutes),
      ],
      restartLabel: i18n.restartFlashcards,
      restartLocation: AppRoutes.play(PlayMode.flashcards),
    );
    context.go(AppRoutes.summary(PlayMode.flashcards), extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(selectedDeckProvider).value;
    final session = _sessionFor(deck);
    final title = PlayMode.flashcards.title(context);
    void goHome() => context.go(AppRoutes.home);

    if (session == null || deck == null || session.isEmpty) {
      return GameScaffold(
        title: title,
        counter: '',
        progress: 0,
        onBack: goHome,
        child: const SizedBox.shrink(),
      );
    }

    final i18n = context.i18n;
    final word = session.current;
    if (word == null) {
      // The round is over and the summary is opening.
      return GameScaffold(
        title: title,
        counter: '',
        progress: 1,
        onBack: goHome,
        child: const SizedBox.shrink(),
      );
    }
    final isFirst = session.index == 0;
    final isLast = session.index == session.total - 1;
    final startLanguage = session.promptLanguage;
    final otherLanguage = startLanguage == PromptLanguage.english
        ? PromptLanguage.hungarian
        : PromptLanguage.english;

    FlashcardFace face(PromptLanguage language, String text) => FlashcardFace(
      language: language,
      text: text,
      onReadAloud: () => _readAloud(session, word),
    );

    return GameScaffold(
      title: title,
      counter: '${session.index + 1} / ${session.total}',
      progress: (session.index + 1) / session.total,
      onBack: goHome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -_swipeVelocity && !isLast) {
                  _goTo(session.advance);
                } else if (velocity > _swipeVelocity && !isFirst) {
                  _goTo(session.back);
                }
              },
              child: FlipCard(
                // A new card starts on its start side, without turning.
                key: ValueKey(session.index),
                showBack: _flipped,
                front: face(startLanguage, session.promptText(word)),
                back: face(otherLanguage, session.answerText(word)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: i18n.previous,
                  onPressed: isFirst ? null : () => _goTo(session.back),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: isLast ? i18n.finish : i18n.next,
                  onPressed: isLast
                      ? () => _finish(session, deck)
                      : () => _goTo(session.advance),
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
