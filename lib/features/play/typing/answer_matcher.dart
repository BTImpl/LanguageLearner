/// Decides whether a typed text is an accepted answer.
///
/// - Upper and lower case do not matter.
/// - Spaces around the text do not matter, several spaces (or tabs, line
///   breaks) between words count as one.
/// - Accents do matter: `utlevel` is not `útlevél`.
/// - An empty text is never right.
abstract final class AnswerMatcher {
  /// The form two texts are compared in: trimmed, single-spaced, lower case.
  static String normalize(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Whether [input] equals any of the [accepted] answers.
  static bool matches(String input, Iterable<String> accepted) {
    final typed = normalize(input);
    if (typed.isEmpty) {
      return false;
    }
    return accepted.any((answer) => normalize(answer) == typed);
  }
}
