/// Decides whether a typed text is an accepted answer.
///
/// - Upper and lower case do not matter.
/// - Spaces around the text do not matter, several spaces (or tabs, line
///   breaks, non-breaking spaces) between words count as one.
/// - Invisible characters (zero-width spaces, soft hyphens, direction marks)
///   are ignored, so a text that only looks right is right.
/// - The curly quotes and the dashes the iOS keyboard writes (`’`, `“`, `–`,
///   `—`) count as the plain `'`, `"` and `-` of the sheet.
/// - A letter typed as a base letter plus a combining accent counts as the
///   same accented letter (`u` + `´` is `ú`).
/// - Accents do matter: `utlevel` is not `útlevél`.
/// - An empty text is never right.
abstract final class AnswerMatcher {
  /// The form two texts are compared in: no invisible characters, plain
  /// quotes and dashes, composed accents, trimmed, single-spaced, lower case.
  static String normalize(String text) {
    final plain = _composeAccents(
      text
          .replaceAll(_invisible, '')
          .replaceAllMapped(_lookalikes, (match) => _lookalikeMap[match[0]]!),
    );
    return plain.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  /// Whether [input] equals any of the [accepted] answers.
  static bool matches(String input, Iterable<String> accepted) {
    final typed = normalize(input);
    if (typed.isEmpty) {
      return false;
    }
    return accepted.any((answer) => normalize(answer) == typed);
  }

  // Zero-width space, non-joiner, joiner, word joiner, byte order mark, soft
  // hyphen, left-to-right and right-to-left marks, the embedding and isolate
  // controls and the Arabic letter mark.
  static final _invisible = RegExp(
    '[\u200B-\u200F\u202A-\u202E\u2060\u2066-\u2069\u061C\uFEFF\u00AD]',
  );

  // Characters the keyboards write instead of the plain ones of the sheet.
  static const _lookalikeMap = {
    '\u2018': "'",
    '\u2019': "'",
    '\u201A': "'",
    '\u201B': "'",
    '\u02BC': "'",
    '\u2032': "'",
    '\u201C': '"',
    '\u201D': '"',
    '\u201E': '"',
    '\u201F': '"',
    '\u2033': '"',
    '\u2010': '-',
    '\u2011': '-',
    '\u2012': '-',
    '\u2013': '-',
    '\u2014': '-',
    '\u2015': '-',
    '\u2212': '-',
    '\u2026': '...',
  };

  static final _lookalikes = RegExp('[${_lookalikeMap.keys.join()}]');

  // A base letter followed by a combining acute (U+0301), diaeresis (U+0308)
  // or double acute (U+030B): the letters of the Hungarian alphabet.
  static const _composed = {
    'a\u0301': '\u00E1',
    'e\u0301': '\u00E9',
    'i\u0301': '\u00ED',
    'o\u0301': '\u00F3',
    'o\u0308': '\u00F6',
    'o\u030B': '\u0151',
    'u\u0301': '\u00FA',
    'u\u0308': '\u00FC',
    'u\u030B': '\u0171',
    'A\u0301': '\u00C1',
    'E\u0301': '\u00C9',
    'I\u0301': '\u00CD',
    'O\u0301': '\u00D3',
    'O\u0308': '\u00D6',
    'O\u030B': '\u0150',
    'U\u0301': '\u00DA',
    'U\u0308': '\u00DC',
    'U\u030B': '\u0170',
  };

  static final _decomposed = RegExp('[AEIOUaeiou][\u0301\u0308\u030B]');

  static String _composeAccents(String text) => text.replaceAllMapped(
    _decomposed,
    (match) => _composed[match[0]] ?? match[0]!,
  );
}
