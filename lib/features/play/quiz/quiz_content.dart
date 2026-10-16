import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/tts_service.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/features/play/quiz/quiz_game.dart';
import 'package:languagelearner/features/play/quiz/quiz_option.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the answer tile that comes from [word], for tests.
Key quizOptionKey(WordPair word) => Key('quiz-option-${word.id}');

/// The body of the quiz: the question card, the four answers and the hint
/// after a wrong choice. It has no frame (title, counters), so the quiz
/// screen and the Mix mode can both use it.
///
/// It shows the state of [game] and must be rebuilt when the game changes.
class QuizContent extends ConsumerWidget {
  const QuizContent({required this.game, super.key});

  final QuizGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = game.current;
    if (word == null) {
      return const SizedBox.shrink();
    }
    final i18n = context.i18n;
    final session = game.session;
    final options = game.options;
    final answered = options.any((o) => o.state == QuizOptionState.correct);
    final hasWrong = options.any((o) => o.state == QuizOptionState.wrong);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionCard(
            label: session.promptIsEnglishFor(word)
                ? i18n.quizQuestionToHungarian
                : i18n.quizQuestionToEnglish,
            text: session.promptText(word),
            onReadAloud: session.promptIsEnglishFor(word)
                ? () =>
                      ref.read(ttsServiceProvider).speak(word.english).ignore()
                : null,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _optionTile(options[i], locked: answered),
          ],
          const SizedBox(height: 12),
          _TryAgainHint(visible: hasWrong && !answered),
        ],
      ),
    );
  }

  Widget _optionTile(QuizOption option, {required bool locked}) {
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
