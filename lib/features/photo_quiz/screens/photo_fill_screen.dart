import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_fill.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_fill_summary.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the tile of the option at [index] of the question on the
/// screen, for tests.
Key photoOptionKey(int index) => Key('photo-option-$index');

/// The key of the "Next" / "Summary" button, for tests.
const Key photoNextKey = Key('photo-next');

/// The key of the "Previous" button, for tests.
const Key photoPreviousKey = Key('photo-previous');

/// Filling in the quiz that was read from the photo: one question on a page,
/// then a summary of the answers (card LL-55).
///
/// Nothing says which option is right, so a chosen option is only highlighted;
/// it is never green or red. Without a ready quiz the screen goes back to the
/// home screen.
class PhotoFillScreen extends ConsumerWidget {
  const PhotoFillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoQuizControllerProvider);
    if (state is! PhotoQuizReady || state.quiz.questions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRoutes.home);
        }
      });
      return Scaffold(backgroundColor: context.colors.background);
    }
    return _FillView(quiz: state.quiz);
  }
}

class _FillView extends ConsumerStatefulWidget {
  const _FillView({required this.quiz});

  final PhotoQuiz quiz;

  @override
  ConsumerState<_FillView> createState() => _FillViewState();
}

class _FillViewState extends ConsumerState<_FillView> {
  var _summary = false;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final quiz = widget.quiz;
    final fill = ref.watch(photoQuizFillProvider(quiz));
    final notifier = ref.read(photoQuizFillProvider(quiz).notifier);
    final title = quiz.title ?? i18n.photoQuizTitle;

    void leave() => context.go(AppRoutes.photoQuizReview);

    if (_summary) {
      return GameScaffold(
        title: title,
        counter: '${fill.answeredCount} / ${fill.questionCount}',
        progress: fill.answeredCount / fill.questionCount,
        confirmLeave: true,
        leaveTitle: i18n.photoQuizLeaveTitle,
        leaveMessage: i18n.photoQuizLeaveMessage,
        onBack: leave,
        child: PhotoFillSummary(
          fill: fill,
          onOpenQuestion: (index) {
            notifier.goTo(index);
            setState(() => _summary = false);
          },
          // The sending itself comes with card LL-56.
          onSubmit: null,
        ),
      );
    }

    final question = fill.currentQuestion;
    final selected = fill.selectedOptionIndex;
    return GameScaffold(
      title: title,
      counter: '${fill.currentIndex + 1} / ${fill.questionCount}',
      progress: (fill.currentIndex + 1) / fill.questionCount,
      confirmLeave: true,
      leaveTitle: i18n.photoQuizLeaveTitle,
      leaveMessage: i18n.photoQuizLeaveMessage,
      onBack: leave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuestionCard(
                    label: i18n.photoQuizFillQuestion(fill.currentIndex + 1),
                    text: question.text,
                    // The question can be in any language, so no read-aloud.
                    onReadAloud: null,
                    fontSize: 24,
                  ),
                  const SizedBox(height: 16),
                  for (final (i, option) in question.options.indexed) ...[
                    if (i > 0) const SizedBox(height: 12),
                    ChoiceTile(
                      key: photoOptionKey(i),
                      label: '${option.label}) ${option.text}',
                      state: selected == i
                          ? ChoiceState.selected
                          : ChoiceState.idle,
                      onTap: () => notifier.select(i),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  key: photoPreviousKey,
                  label: i18n.photoQuizPrevious,
                  icon: Icons.chevron_left,
                  onPressed: fill.isFirst ? null : notifier.previous,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  key: photoNextKey,
                  label: fill.isLast
                      ? i18n.photoQuizToSummary
                      : i18n.photoQuizNext,
                  onPressed: fill.isLast
                      ? () => setState(() => _summary = true)
                      : notifier.next,
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
