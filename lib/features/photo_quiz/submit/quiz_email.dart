import 'dart:convert';

import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';
import 'package:languagelearner/features/photo_quiz/models/photo_quiz_answers.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

/// The subject and the text of the e-mail with the answers.
class QuizEmail {
  const QuizEmail({
    required this.subject,
    required this.body,
    required this.html,
  });

  final String subject;

  /// Plain text.
  final String body;

  /// The same content as HTML with inline styles, which the mail editors
  /// show formatted.
  final String html;
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

  final header = [
    l10n.photoEmailStudent(studentName, studentEmail),
    l10n.photoEmailDate(_isoDate(date)),
    l10n.photoQuizSummaryProgress(answers.answeredCount, quiz.questions.length),
  ];
  final lines = [...header];
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
  return QuizEmail(
    subject: subject,
    body: lines.join('\n'),
    html: _html(l10n, quiz, answers, header),
  );
}

const _escape = HtmlEscape(HtmlEscapeMode.element);

String _html(
  AppLocalizations l10n,
  PhotoQuiz quiz,
  PhotoQuizAnswers answers,
  List<String> header,
) {
  final out = StringBuffer()
    ..write(
      '<div style="font-family:-apple-system,Helvetica,Arial,sans-serif;'
      'font-size:16px;line-height:1.45;color:#1a1a1a">',
    )
    ..write('<p style="margin:0 0 2px">${_escape.convert(header[0])}</p>')
    ..write('<p style="margin:0 0 2px">${_escape.convert(header[1])}</p>')
    ..write(
      '<p style="margin:0;font-weight:bold">${_escape.convert(header[2])}</p>',
    )
    ..write('<hr style="border:0;border-top:1px solid #d0d0d0;margin:16px 0">');
  for (final (index, question) in quiz.questions.indexed) {
    final chosen = answers.selectedIndex(index);
    out
      ..write('<div style="margin:0 0 20px">')
      ..write(
        '<p style="margin:0 0 8px;font-weight:bold">'
        '${index + 1}. ${_escape.convert(question.text)}</p>',
      );
    for (final (optionIndex, option) in question.options.indexed) {
      final text = _escape.convert('${option.label}) ${option.text}');
      if (chosen == optionIndex) {
        out.write(
          '<div style="margin:0 0 4px 12px;padding:5px 10px;'
          'background:#e3ecff;border-left:4px solid #2f5bd8;'
          'font-weight:bold;color:#14307f">\u2714 $text</div>',
        );
      } else {
        out.write(
          '<div style="margin:0 0 4px 12px;padding:5px 10px;color:#555555">'
          '\u25CB $text</div>',
        );
      }
    }
    if (chosen == null) {
      out.write(
        '<div style="margin:6px 0 0 12px;color:#c0392b;font-style:italic">'
        '${_escape.convert(l10n.photoQuizNoAnswer)}</div>',
      );
    }
    out.write('</div>');
  }
  out.write('</div>');
  return out.toString();
}

String _isoDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
      '${two(date.day)}';
}
