import 'package:flutter/foundation.dart';
import 'package:languagelearner/core/models/word_pair.dart';

/// A named list of words, one tab of the student's spreadsheet.
///
/// The shape matches the deck API of the backend (card BE-05).
@immutable
class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.words,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// In the order of the spreadsheet; shuffling is up to the game screens.
  final List<WordPair> words;

  /// When the words were last read from the spreadsheet.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is Deck &&
      other.id == id &&
      other.name == name &&
      listEquals(other.words, words) &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(words), updatedAt);

  @override
  String toString() => 'Deck($id: $name, ${words.length} words)';
}
