import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/state_message.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz.dart';
import 'package:languagelearner/features/photo_quiz/saved/saved_quiz_providers.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_controller.dart';
import 'package:languagelearner/features/photo_quiz/widgets/photo_quiz_header.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the row of the saved quiz with [id], for tests.
Key savedQuizRowKey(String id) => Key('saved-quiz-$id');

/// The key of the delete button of the saved quiz with [id], for tests.
Key savedQuizDeleteKey(String id) => Key('saved-quiz-delete-$id');

/// The key of the button of the empty list that opens the photo screen.
const Key savedQuizzesPhotoKey = Key('saved-quizzes-photo');

/// The quizzes that were read from photos and kept on the phone (card LL-68):
/// a tap fills the quiz in again, from the start and without answers.
///
/// - Sorted by the last use, the latest first.
/// - A deleted quiz can be put back with the "Undo" action of the message.
class SavedQuizzesScreen extends ConsumerWidget {
  const SavedQuizzesScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    SavedQuiz entry,
  ) async {
    final notifier = ref.read(savedQuizzesProvider.notifier);
    final controller = ref.read(photoQuizControllerProvider.notifier);
    SavedQuiz? used;
    try {
      used = await notifier.start(entry);
    } on Object {
      // The count is not important; the quiz still opens.
      used = entry;
    }
    if (used == null || !context.mounted) {
      return;
    }
    controller.loadSaved(used.quiz);
    context.go(AppRoutes.photoQuizFill);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SavedQuiz entry,
  ) async {
    final i18n = context.i18n;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(savedQuizzesProvider.notifier);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(i18n.photoQuizSavedDeleted),
          action: SnackBarAction(
            label: i18n.photoQuizUndo,
            onPressed: () => unawaited(notifier.restore(entry)),
          ),
        ),
      );
    await notifier.delete(entry);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final c = context.colors;
    final saved = ref.watch(savedQuizzesProvider);
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
                title: i18n.photoQuizSavedTitle,
                onBack: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  context.go(AppRoutes.photoQuiz);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch (saved) {
                  AsyncData(:final value) when value.isEmpty => Center(
                    child: SingleChildScrollView(
                      child: StateMessage(
                        icon: Icons.history,
                        title: i18n.photoQuizSavedEmptyTitle,
                        message: i18n.photoQuizSavedEmptyMessage,
                        actionLabel: i18n.photoQuizTakePhoto,
                        onAction: () => context.go(AppRoutes.photoQuiz),
                      ),
                    ),
                  ),
                  AsyncData(:final value) => ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: value.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) => _SavedQuizRow(
                      entry: value[index],
                      onOpen: () =>
                          unawaited(_open(context, ref, value[index])),
                      onDelete: () =>
                          unawaited(_delete(context, ref, value[index])),
                    ),
                  ),
                  AsyncError() => Center(
                    child: StateMessage(
                      icon: Icons.error_outline,
                      title: i18n.photoQuizSavedLoadFailed,
                      message: i18n.photoQuizErrorGeneral,
                      actionLabel: i18n.photoQuizRetry,
                      onAction: () => ref.invalidate(savedQuizzesProvider),
                    ),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedQuizRow extends StatelessWidget {
  const _SavedQuizRow({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });

  final SavedQuiz entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    final title = entry.quiz.title ?? i18n.photoQuizSavedUntitled;
    final date = MaterialLocalizations.of(context)
        .formatCompactDate(entry.lastUsedAt.toLocal());
    final details = [
      i18n.photoQuizQuestionCount(entry.quiz.questions.length),
      date,
      i18n.photoQuizSavedFillCount(entry.fillCount),
    ].join(' · ');
    return AppCard(
      key: savedQuizRowKey(entry.id),
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: AppRadii.tile,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 14,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            key: savedQuizDeleteKey(entry.id),
            onPressed: onDelete,
            tooltip: i18n.photoQuizSavedDeleteQuiz(title),
            color: c.errorNumber,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
