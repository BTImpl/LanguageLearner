import 'package:languagelearner/features/photo_quiz/models/photo_quiz.dart';

// Everything that is not a letter or a digit, in any alphabet.
final _notLetterOrDigit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// The text without case, spaces and punctuation: what stays the same when
/// the same worksheet is read twice. Accents stay, they change the word.
String normalizeQuizText(String text) =>
    text.toLowerCase().replaceAll(_notLetterOrDigit, '');

/// Tells quizzes apart by their content: the same worksheet read again gives
/// the same fingerprint, even when the reading differs in case, spaces or
/// punctuation.
///
/// The title and the numbers printed on the sheet do not count; the order of
/// the questions and of the options does, and so does the text of each.
String quizFingerprint(PhotoQuiz quiz) {
  final canonical = StringBuffer();
  for (final question in quiz.questions) {
    canonical
      ..write(normalizeQuizText(question.text))
      ..write('\u0001');
    for (final option in question.options) {
      canonical
        ..write(normalizeQuizText(option.label))
        ..write('\u0004')
        ..write(normalizeQuizText(option.text))
        ..write('\u0002');
    }
    canonical.write('\u0003');
  }
  return _fnv1a64(canonical.toString());
}

/// FNV-1a over the UTF-16 code units: a short, stable id, which does not need
/// to be secret (only to tell a few dozen quizzes apart).
String _fnv1a64(String text) {
  const offset = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  var hash = offset;
  for (final unit in text.codeUnits) {
    hash = (hash ^ unit) * prime;
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}
