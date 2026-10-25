import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/core/widgets/game_scaffold.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/core/widgets/state_message.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_fill.dart';
import 'package:languagelearner/features/photo_quiz/submit/photo_quiz_submit.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_fill_summary.dart';
import 'package:languagelearner/features/play/widgets/question_card.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
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
    return _FillView(quiz: state.quiz, fromSaved: state.fromSaved);
  }
}

class _FillView extends ConsumerStatefulWidget {
  const _FillView({required this.quiz, required this.fromSaved});

  final PhotoQuiz quiz;
  final bool fromSaved;

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

    // A quiz from the saved list goes back to the list: it has no review.
    void leave() => context.go(
      widget.fromSaved ? AppRoutes.photoQuizSaved : AppRoutes.photoQuizReview,
    );

    final submit = ref.watch(photoQuizSubmitProvider);
    if (submit is SubmitSent) {
      return _SentView(
        onDone: () {
          ref.read(photoQuizControllerProvider.notifier).reset();
          context.go(AppRoutes.home);
        },
      );
    }

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
          noRecipient: ref.watch(
            settingsProvider.select((s) => s.teacherEmail.isEmpty),
          ),
          sending: submit is SubmitSending,
          errorText: switch (submit) {
            SubmitFailed(failure: SubmitFailure.noMailApp) =>
              i18n.photoQuizSendNoMailApp,
            SubmitFailed(failure: SubmitFailure.failed) =>
              i18n.photoQuizSendFailed,
            _ => null,
          },
          onSubmit: () => unawaited(
            ref
                .read(photoQuizSubmitProvider.notifier)
                .submit(answers: fill.answers, l10n: i18n),
          ),
          // Pushed, so the answers stay where they are.
          onOpenSettings: () => unawaited(context.push(AppRoutes.settings)),
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

/// The closing screen: the e-mail is in the mail app. The app cannot tell
/// whether the student sent it, so it does not say it arrived.
class _SentView extends StatelessWidget {
  const _SentView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          onDone();
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenMargin,
            ),
            child: Center(
              child: SingleChildScrollView(
                child: StateMessage(
                  icon: Icons.mark_email_read_outlined,
                  title: i18n.photoQuizSentTitle,
                  message: i18n.photoQuizSentMessage,
                  actionLabel: i18n.photoQuizSentDone,
                  onAction: onDone,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
