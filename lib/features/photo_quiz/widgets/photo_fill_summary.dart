import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/photo_quiz/state/photo_quiz_fill.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The key of the row of the question at [index], for tests.
Key photoSummaryRowKey(int index) => Key('photo-summary-row-$index');

/// The key of the "Send to teacher" button, for tests.
const Key photoSubmitKey = Key('photo-submit');

/// Every question with the chosen answer, before the quiz is sent.
///
/// A question without an answer is marked, but the quiz can be sent with it
/// too (it goes as "no answer"). Tapping a row opens that question.
class PhotoFillSummary extends StatelessWidget {
  const PhotoFillSummary({
    required this.fill,
    required this.onOpenQuestion,
    required this.onSubmit,
    super.key,
  });

  final PhotoQuizFillState fill;

  /// Called with the position of the tapped question.
  final ValueChanged<int> onOpenQuestion;

  /// `null` disables the send button.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final answers = fill.answers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          i18n.photoQuizSummaryProgress(fill.answeredCount, fill.questionCount),
          style: TextStyle(
            fontFamily: bodyFontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: fill.isComplete ? c.text : c.errorNumber,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: fill.questionCount,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final question = fill.quiz.questions[index];
              final option = answers.selectedOption(index);
              return _SummaryRow(
                key: photoSummaryRowKey(index),
                number: index + 1,
                question: question.text,
                answer: option == null
                    ? null
                    : '${option.label}) ${option.text}',
                onTap: () => onOpenQuestion(index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          key: photoSubmitKey,
          label: i18n.photoQuizSubmit,
          icon: Icons.send_outlined,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.number,
    required this.question,
    required this.answer,
    required this.onTap,
    super.key,
  });

  final int number;
  final String question;

  /// `null` when the question is not answered.
  final String? answer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final unanswered = answer == null;
    return Semantics(
      button: true,
      label: i18n.photoQuizOpenQuestion(number),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.choice,
          side: BorderSide(
            color: unanswered ? c.errorBorder : c.line,
            width: unanswered ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadii.choice,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $question',
                  style: TextStyle(
                    fontFamily: bodyFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unanswered) ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 22,
                        color: c.errorNumber,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        answer ?? i18n.photoQuizNoAnswer,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: unanswered ? c.errorNumber : c.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
