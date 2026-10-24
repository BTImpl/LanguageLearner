import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_answers.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

/// The subject and the text of the e-mail with the answers.
class QuizEmail {
  const QuizEmail({required this.subject, required this.body});

  final String subject;
  final String body;
}

/// Writes the e-mail that sends the filled-in quiz to the teacher, in the
/// language of [l10n].
///
/// The subject is "title – student" (the generic quiz title when the
/// worksheet has none). The body is plain text: who sends it and when, then
/// every question by position with all its options, the chosen one marked
/// `[x]`; a question without a choice says "no answer".
QuizEmail buildQuizEmail({
  required AppLocalizations l10n,
  required PhotoQuiz quiz,
  required PhotoQuizAnswers answers,
  required String studentName,
  required String studentEmail,
  required DateTime date,
}) {
  final title = quiz.title ?? l10n.photoQuizTitle;
  final subject = studentName.isEmpty ? title : '$title – $studentName';

  final lines = <String>[
    l10n.photoEmailStudent(studentName, studentEmail),
    l10n.photoEmailDate(_isoDate(date)),
    l10n.photoQuizSummaryProgress(answers.answeredCount, quiz.questions.length),
  ];
  for (final (index, question) in quiz.questions.indexed) {
    final chosen = answers.selectedIndex(index);
    lines
      ..add('')
      ..add('${index + 1}. ${question.text}');
    for (final (optionIndex, option) in question.options.indexed) {
      final mark = chosen == optionIndex ? '[x]' : '[ ]';
      lines.add('   $mark ${option.label}) ${option.text}');
    }
    if (chosen == null) {
      lines.add('   ${l10n.photoQuizNoAnswer}');
    }
  }
  return QuizEmail(subject: subject, body: lines.join('\n'));
}

String _isoDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
      '${two(date.day)}';
}
