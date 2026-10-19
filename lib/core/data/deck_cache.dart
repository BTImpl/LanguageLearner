import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:languagelearner/core/database/app_database.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';

/// The decks as they were downloaded, and when.
class DeckSnapshot {
  const DeckSnapshot({required this.decks, required this.fetchedAt});

  final List<Deck> decks;

  /// When the phone downloaded the decks.
  final DateTime fetchedAt;
}

/// Where the last downloaded decks are kept on the phone, so the student can
/// practice without a network. The `CachedWordRepository` is the only user.
abstract interface class DeckCache {
  /// The saved decks, `null` if there are none.
  Future<DeckSnapshot?> read();

  /// Replaces everything saved with [decks]: either all of them are saved or
  /// the old ones stay.
  Future<void> replace(List<Deck> decks, DateTime fetchedAt);

  /// Forgets everything saved.
  Future<void> clear();
}

/// [DeckCache] on top of the local SQLite database.
///
/// An empty list of decks is saved as nothing, so [read] gives `null` for it.
/// The database keeps whole seconds and gives local times back, so the times
/// are turned to UTC again.
class DriftDeckCache implements DeckCache {
  DriftDeckCache(this._db);

  final AppDatabase _db;

  @override
  Future<DeckSnapshot?> read() {
    return _db.transaction(() async {
      final deckRows = await (_db.select(
        _db.cachedDecks,
      )..orderBy([(row) => OrderingTerm.asc(row.position)])).get();
      if (deckRows.isEmpty) {
        return null;
      }
      final wordRows = await (_db.select(
        _db.cachedWords,
      )..orderBy([(row) => OrderingTerm.asc(row.position)])).get();
      final wordsByDeck = <String, List<WordPair>>{};
      for (final row in wordRows) {
        wordsByDeck.putIfAbsent(row.deckId, () => []).add(_toWord(row));
      }
      return DeckSnapshot(
        decks: [
          for (final row in deckRows)
            Deck(
              id: row.id,
              name: row.name,
              words: wordsByDeck[row.id] ?? const [],
              updatedAt: row.updatedAt.toUtc(),
            ),
        ],
        fetchedAt: deckRows.first.fetchedAt.toUtc(),
      );
    });
  }

  @override
  Future<void> replace(List<Deck> decks, DateTime fetchedAt) {
    return _db.transaction(() async {
      await _db.delete(_db.cachedWords).go();
      await _db.delete(_db.cachedDecks).go();
      await _db.batch((batch) {
        batch.insertAll(_db.cachedDecks, [
          for (final (index, deck) in decks.indexed)
            CachedDecksCompanion.insert(
              id: deck.id,
              name: deck.name,
              position: index,
              updatedAt: deck.updatedAt,
              fetchedAt: fetchedAt,
            ),
        ]);
        batch.insertAll(_db.cachedWords, [
          for (final deck in decks)
            for (final (index, word) in deck.words.indexed)
              CachedWordsCompanion.insert(
                deckId: deck.id,
                id: word.id,
                position: index,
                english: word.english,
                hungarian: word.hungarian,
                acceptedEnglish: jsonEncode(word.acceptedEnglish),
                acceptedHungarian: jsonEncode(word.acceptedHungarian),
                example: Value(word.example),
              ),
        ]);
      });
    });
  }

  @override
  Future<void> clear() {
    return _db.transaction(() async {
      await _db.delete(_db.cachedWords).go();
      await _db.delete(_db.cachedDecks).go();
    });
  }
}

WordPair _toWord(CachedWordRow row) => WordPair(
  id: row.id,
  english: row.english,
  hungarian: row.hungarian,
  acceptedEnglish: _decodeTexts(row.acceptedEnglish),
  acceptedHungarian: _decodeTexts(row.acceptedHungarian),
  example: row.example,
);

List<String> _decodeTexts(String json) => [
  for (final text in jsonDecode(json) as List<Object?>) text as String,
];

/// [DeckCache] that keeps everything in memory, for tests.
class InMemoryDeckCache implements DeckCache {
  InMemoryDeckCache([this.snapshot]);

  DeckSnapshot? snapshot;

  /// How many times [replace] was called.
  var replaceCalls = 0;

  @override
  Future<DeckSnapshot?> read() async => snapshot;

  @override
  Future<void> replace(List<Deck> decks, DateTime fetchedAt) async {
    replaceCalls++;
    snapshot = decks.isEmpty
        ? null
        : DeckSnapshot(decks: decks, fetchedAt: fetchedAt);
  }

  @override
  Future<void> clear() async => snapshot = null;
}
