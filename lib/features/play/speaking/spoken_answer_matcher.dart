import 'package:flutter/foundation.dart';

/// Why a spoken answer was accepted or rejected.
enum MatchKind {
  /// The best reading equals the expected text.
  exact,

  /// The best reading is a small, allowed distance from the expected text.
  close,

  /// The best reading sounds the same as the expected word (to / two).
  homophone,

  /// Not the best reading, but another reading of the recogniser matches.
  alternative,

  /// Nothing matches.
  none,

  /// Nothing was recognised.
  nothing,
}

/// The verdict on one spoken answer.
@immutable
class MatchDecision {
  const MatchDecision({required this.kind, this.matched});

  final MatchKind kind;

  /// The reading that was accepted, as the recogniser wrote it.
  final String? matched;

  bool get accepted => switch (kind) {
    MatchKind.exact ||
    MatchKind.close ||
    MatchKind.homophone ||
    MatchKind.alternative => true,
    MatchKind.none || MatchKind.nothing => false,
  };

  @override
  bool operator ==(Object other) =>
      other is MatchDecision && other.kind == kind && other.matched == matched;

  @override
  int get hashCode => Object.hash(kind, matched);

  @override
  String toString() => 'MatchDecision($kind, $matched)';
}

/// Words that sound the same, kept by hand. Every group holds the normalized
/// spellings (see [normalizeSpoken]).
const List<Set<String>> homophoneGroups = [
  {'to', 'too', 'two'},
  {'there', 'their', 'theyre'},
  {'write', 'right', 'rite'},
  {'know', 'no'},
  {'see', 'sea'},
  {'buy', 'by', 'bye'},
  {'hear', 'here'},
  {'one', 'won'},
  {'for', 'four', 'fore'},
  {'son', 'sun'},
  {'be', 'bee'},
  {'wear', 'where', 'ware'},
  {'weather', 'whether'},
  {'which', 'witch'},
  {'new', 'knew'},
  {'whole', 'hole'},
  {'meet', 'meat'},
  {'week', 'weak'},
  {'wait', 'weight'},
  {'flower', 'flour'},
  {'our', 'hour'},
  {'through', 'threw'},
  {'peace', 'piece'},
  {'plain', 'plane'},
  {'tail', 'tale'},
  {'bear', 'bare'},
  {'dear', 'deer'},
  {'eye', 'i'},
  {'in', 'inn'},
  {'mail', 'male'},
  {'pair', 'pear', 'pare'},
  {'road', 'rode'},
  {'sail', 'sale'},
  {'steal', 'steel'},
  {'wood', 'would'},
  {'your', 'youre'},
  {'sea', 'see'},
];

final RegExp _notLetterOrDigit = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
final RegExp _spaces = RegExp(r'\s+');

/// Lower case, no punctuation, single spaces: the form two texts are compared
/// in. `Don't  Stop!` becomes `dont stop`.
String normalizeSpoken(String text) {
  return text
      .toLowerCase()
      .replaceAll(_notLetterOrDigit, '')
      .replaceAll(_spaces, ' ')
      .trim();
}

/// How many letters may differ for a text of [length] letters: none up to 5
/// letters (a changed letter makes another word: house / horse / mouse), one
/// for 6-8 letters and two for longer ones.
int allowedDistance(int length) {
  if (length <= 5) {
    return 0;
  }
  if (length <= 8) {
    return 1;
  }
  return 2;
}

/// The Levenshtein distance of [a] and [b].
int editDistance(String a, String b) {
  if (a == b) {
    return 0;
  }
  if (a.isEmpty) {
    return b.length;
  }
  if (b.isEmpty) {
    return a.length;
  }
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      final substitution = previous[j - 1] + cost;
      var best = deletion < insertion ? deletion : insertion;
      if (substitution < best) {
        best = substitution;
      }
      current[j] = best;
    }
    previous = current;
  }
  return previous[b.length];
}

bool _sameSound(String a, String b) {
  for (final group in homophoneGroups) {
    if (group.contains(a) && group.contains(b)) {
      return true;
    }
  }
  return false;
}

/// How [heard] relates to one [expected] text, both normalized: the strongest
/// kind that fits, or `null`.
MatchKind? _relation(String heard, String expected) {
  if (heard == expected) {
    return MatchKind.exact;
  }
  if (_sameSound(heard, expected)) {
    return MatchKind.homophone;
  }
  if (editDistance(heard, expected) <= allowedDistance(expected.length)) {
    return MatchKind.close;
  }
  return null;
}

/// Decides whether the student said one of the [expected] texts.
///
/// [expected] holds all accepted answers (the variants of the sheet cell).
/// [heard] holds the readings of the recogniser, the best one first.
///
/// The best reading is judged first; if it does not fit, the other readings
/// are tried, and a fit there is an [MatchKind.alternative].
MatchDecision decideSpokenAnswer({
  required List<String> expected,
  required List<String> heard,
}) {
  final wanted = [
    for (final text in expected)
      if (normalizeSpoken(text).isNotEmpty) normalizeSpoken(text),
  ];
  final readings = [
    for (final text in heard)
      if (normalizeSpoken(text).isNotEmpty) text,
  ];
  if (readings.isEmpty) {
    return const MatchDecision(kind: MatchKind.nothing);
  }
  for (var i = 0; i < readings.length; i++) {
    final reading = normalizeSpoken(readings[i]);
    MatchKind? best;
    for (final text in wanted) {
      final kind = _relation(reading, text);
      if (kind != null && (best == null || kind.index < best.index)) {
        best = kind;
      }
    }
    if (best != null) {
      return MatchDecision(
        kind: i == 0 ? best : MatchKind.alternative,
        matched: readings[i],
      );
    }
  }
  return const MatchDecision(kind: MatchKind.none);
}
