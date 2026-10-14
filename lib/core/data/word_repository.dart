import 'package:languagelearner/core/models/deck.dart';

/// Where the decks come from.
///
/// The screens only know this interface. The app starts with the
/// `FakeWordRepository`; card LL-28 adds the one that asks the backend.
abstract interface class WordRepository {
  /// All decks of the signed-in student, with their words.
  Future<List<Deck>> getDecks();

  /// Reads the decks again from the source (the teacher may have changed the
  /// spreadsheet). The next [getDecks] returns the fresh data.
  Future<void> refresh();
}
