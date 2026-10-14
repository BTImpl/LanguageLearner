import 'package:flutter/foundation.dart';

/// Splits a spreadsheet cell into its `;`-separated variants.
///
/// Whitespace around a variant is trimmed and empty variants are skipped, so
/// `'jegy; menetjegy ;'` gives `['jegy', 'menetjegy']`.
List<String> parseVariants(String cell) {
  return [
    for (final part in cell.split(';'))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}

/// One English word or phrase with its Hungarian meaning.
///
/// The shape matches the `words` of the backend deck API (card BE-05).
@immutable
class WordPair {
  const WordPair({
    required this.id,
    required this.english,
    required this.hungarian,
    required this.acceptedEnglish,
    required this.acceptedHungarian,
    this.example,
  });

  /// Builds a word from the two spreadsheet cells.
  ///
  /// Each cell may hold several `;`-separated variants. All of them are
  /// accepted as an exact answer, the first one is the text that is shown.
  /// Throws an [ArgumentError] if a cell has no variant at all.
  factory WordPair.fromCells({
    required String id,
    required String english,
    required String hungarian,
    String? example,
  }) {
    final acceptedEnglish = parseVariants(english);
    final acceptedHungarian = parseVariants(hungarian);
    if (acceptedEnglish.isEmpty || acceptedHungarian.isEmpty) {
      throw ArgumentError(
        'Word "$id" needs an English and a Hungarian text, '
        'got "$english" and "$hungarian".',
      );
    }
    final trimmedExample = example?.trim();
    return WordPair(
      id: id,
      english: acceptedEnglish.first,
      hungarian: acceptedHungarian.first,
      acceptedEnglish: acceptedEnglish,
      acceptedHungarian: acceptedHungarian,
      example: (trimmedExample == null || trimmedExample.isEmpty)
          ? null
          : trimmedExample,
    );
  }

  final String id;

  /// The English text that is shown.
  final String english;

  /// The Hungarian text that is shown.
  final String hungarian;

  /// Every English text accepted as an exact answer.
  final List<String> acceptedEnglish;

  /// Every Hungarian text accepted as an exact answer.
  final List<String> acceptedHungarian;

  /// An optional example sentence.
  final String? example;

  @override
  bool operator ==(Object other) =>
      other is WordPair &&
      other.id == id &&
      other.english == english &&
      other.hungarian == hungarian &&
      listEquals(other.acceptedEnglish, acceptedEnglish) &&
      listEquals(other.acceptedHungarian, acceptedHungarian) &&
      other.example == example;

  @override
  int get hashCode => Object.hash(
    id,
    english,
    hungarian,
    Object.hashAll(acceptedEnglish),
    Object.hashAll(acceptedHungarian),
    example,
  );

  @override
  String toString() => 'WordPair($id: $english = $hungarian)';
}
