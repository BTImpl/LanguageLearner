import 'package:languagelearner/core/models/deck.dart';

/// Where the decks come from.
///
/// The screens only know this interface. The app uses the
/// `CachedWordRepository` (saved decks over the backend), or the
/// `FakeWordRepository` for trying it out.
abstract interface class WordRepository {
  /// All decks of the signed-in student, with their words.
  Future<List<Deck>> getDecks();

  /// Reads the decks again from the source (the teacher may have changed the
  /// spreadsheet). The next [getDecks] returns the fresh data.
  Future<void> refresh();

  /// Forgets the decks saved on the phone, when the student signs out: the
  /// next student must not see them.
  Future<void> clearLocal();
}
