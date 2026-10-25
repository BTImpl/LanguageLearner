import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_question.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz_store.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_header.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The student looks through the questions that were read from the photo and
/// deletes the ones that were read wrongly, before filling in the quiz.
///
/// - A deleted question can be put back with the "Undo" action of the message
///   that appears (only the last deletion, as the next message replaces it).
/// - The questions keep the numbers printed on the worksheet; the screen where
///   the quiz is filled in numbers the remaining ones again.
/// - Nothing can be edited: when the reading is bad, the way out is a new
///   photo ("Retake photo", which throws this quiz away).
/// - "Start" is disabled when every question is deleted.
///
/// Without a ready quiz it goes back to the home screen.
class PhotoReviewScreen extends ConsumerWidget {
  const PhotoReviewScreen({super.key});

  void _delete(
    BuildContext context,
    WidgetRef ref,
    int index,
    PhotoQuizQuestion question,
  ) {
    final i18n = context.i18n;
    final controller = ref.read(photoQuizControllerProvider.notifier)
      ..removeQuestion(index);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // Above the buttons, so that they stay reachable while it is shown.
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            AppSizes.screenMargin,
            0,
            AppSizes.screenMargin,
            _buttonsHeight(context),
          ),
          content: Text(i18n.photoQuizQuestionDeleted),
          action: SnackBarAction(
            label: i18n.photoQuizUndo,
            onPressed: () => controller.restoreQuestion(index, question),
          ),
        ),
      );
  }

  /// Whether a large text size puts the two buttons under each other.
  static bool _stacked(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.2;

  /// The room the buttons and the space around them take at the bottom.
  static double _buttonsHeight(BuildContext context) {
    const gap = 12.0;
    final rows = _stacked(context) ? 2 : 1;
    return rows * AppSizes.buttonHeight + (rows - 1) * gap + 20 + gap;
  }

  void _leave(BuildContext context, WidgetRef ref, String location) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (location != AppRoutes.photoQuizFill) {
      ref.read(photoQuizControllerProvider.notifier).reset();
    }
    context.go(location);
  }

  /// Keeps the quiz on the phone and starts filling it in. A failing storage
  /// never keeps the student from the quiz.
  void _start(BuildContext context, WidgetRef ref, PhotoQuiz quiz) {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.i18n.photoQuizSavedDuplicate;
    final store = ref.read(savedQuizStoreProvider);
    final student = ref.read(accountProvider)?.email;
    final now = ref.read(clockProvider)();
    _leave(context, ref, AppRoutes.photoQuizFill);
    if (student == null) {
      return;
    }
    unawaited(() async {
      try {
        final recorded = await store.record(student, quiz, now);
        if (recorded.duplicate) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        }
      } on Object {
        // Not saved, but the quiz can still be filled in.
      }
    }());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final c = context.colors;
    final state = ref.watch(photoQuizControllerProvider);
    if (state is! PhotoQuizReady) {
      // Not when the student is already on the way somewhere else (the quiz
      // is dropped by "Retake photo" before the screen is gone).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            GoRouter.of(context).routerDelegate.currentConfiguration.uri.path ==
                AppRoutes.photoQuizReview) {
          context.go(AppRoutes.home);
        }
      });
      return Scaffold(backgroundColor: c.background);
    }
    final quiz = state.quiz;
    final retake = SecondaryButton(
      label: i18n.photoQuizRetake,
      icon: Icons.photo_camera_outlined,
      onPressed: () => _leave(context, ref, AppRoutes.photoQuiz),
    );
    final start = PrimaryButton(
      label: i18n.photoQuizStart,
      icon: Icons.chevron_right,
      onPressed: quiz.questions.isEmpty
          ? null
          : () => _start(context, ref, quiz),
    );
    // Side by side, unless a large text size leaves no room for it.
    final stacked = _stacked(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              PhotoQuizHeader(
                title: i18n.photoQuizTitle,
                onBack: () => _leave(context, ref, AppRoutes.home),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 20, bottom: 12),
                  children: [
                    Text(
                      i18n.photoQuizReviewHeadline,
                      style: TextStyle(
                        fontFamily: headingFontFamily,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i18n.photoQuizReviewSubtitle,
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 16,
                        height: 1.4,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _TitleRow(quiz: quiz),
                    if (quiz.skippedQuestions > 0) ...[
                      const SizedBox(height: 12),
                      _SkippedNote(count: quiz.skippedQuestions),
                    ],
                    const SizedBox(height: 12),
                    if (quiz.questions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          i18n.photoQuizReviewEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: bodyFontFamily,
                            fontSize: 16,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    for (final (index, question) in quiz.questions.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuestionCard(
                          question: question,
                          onDelete: () =>
                              _delete(context, ref, index, question),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (stacked) ...[
                start,
                const SizedBox(height: 12),
                retake,
              ] else
                Row(
                  children: [
                    Expanded(child: retake),
                    const SizedBox(width: 12),
                    Expanded(child: start),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// The title of the worksheet (or the general title) and how many questions
/// are left.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.quiz});

  final PhotoQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            quiz.title ?? i18n.photoQuizTitle,
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Text(
            i18n.photoQuizQuestionCount(quiz.questions.length),
            style: TextStyle(
              fontFamily: bodyFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkippedNote extends StatelessWidget {
  const _SkippedNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: AppRadii.choice,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.info_outline, color: c.highlight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.i18n.photoQuizSkipped(count),
                style: TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 15,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One question: its printed number, the text, the options in small print and
/// the delete button. Long texts wrap.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.onDelete});

  final PhotoQuizQuestion question;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${question.number}',
              style: TextStyle(
                fontFamily: bodyFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    question.text,
                    style: TextStyle(
                      fontFamily: bodyFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: c.text,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in question.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${option.label}) ${option.text}',
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 14,
                        height: 1.35,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: c.errorNumber,
                      minimumSize: const Size(0, AppSizes.touchTarget),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      i18n.photoQuizDelete,
                      semanticsLabel: i18n.photoQuizDeleteQuestion(
                        question.number,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
