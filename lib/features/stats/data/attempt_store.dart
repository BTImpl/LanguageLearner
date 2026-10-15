import 'package:drift/drift.dart';
import 'package:languagelearner/core/database/app_database.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';

/// Where the attempts are kept. The statistics logic only knows this
/// interface, so it runs on the real database and on a plain list in tests.
abstract interface class AttemptStore {
  /// Saves all [records] at once: either every one of them is saved or none.
  Future<void> insertAll(List<AttemptRecord> records);

  /// Every attempt on words of [deckId], the oldest first.
  Future<List<AttemptRecord>> forDeck(String deckId);
}

/// [AttemptStore] on top of the local SQLite database.
class DriftAttemptStore implements AttemptStore {
  DriftAttemptStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> insertAll(List<AttemptRecord> records) {
    return _db.batch((batch) {
      batch.insertAll(_db.attempts, [
        for (final record in records)
          AttemptsCompanion.insert(
            id: record.id,
            deckId: record.deckId,
            wordId: record.wordId,
            mode: record.mode.name,
            outcome: record.outcome.name,
            answeredAt: record.answeredAt,
            synced: Value(record.synced),
          ),
      ]);
    });
  }

  @override
  Future<List<AttemptRecord>> forDeck(String deckId) async {
    final query = _db.select(_db.attempts)
      ..where((row) => row.deckId.equals(deckId))
      ..orderBy([(row) => OrderingTerm.asc(row.answeredAt)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        AttemptRecord(
          id: row.id,
          deckId: row.deckId,
          wordId: row.wordId,
          mode: PlayMode.values.byName(row.mode),
          outcome: WordOutcome.values.byName(row.outcome),
          answeredAt: row.answeredAt,
          synced: row.synced,
        ),
    ];
  }
}

/// [AttemptStore] that keeps everything in memory. It is the default of the
/// app providers (so widget tests need no database) and is used in tests.
class InMemoryAttemptStore implements AttemptStore {
  final _records = <AttemptRecord>[];

  @override
  Future<void> insertAll(List<AttemptRecord> records) async {
    _records.addAll(records);
  }

  @override
  Future<List<AttemptRecord>> forDeck(String deckId) async {
    final matching = [
      for (final record in _records)
        if (record.deckId == deckId) record,
    ];
    // Stable: records with the same time stay in insertion order.
    final indexed = matching.indexed.toList()
      ..sort((a, b) {
        final byTime = a.$2.answeredAt.compareTo(b.$2.answeredAt);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }
}
