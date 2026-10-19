import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// One answered word of a finished round.
///
/// The [id] is generated on the phone, so uploading the row to the backend
/// again (card LL-30) can never create a duplicate there.
@DataClassName('AttemptRow')
@TableIndex(name: 'attempt_deck_word', columns: {#deckId, #wordId})
class Attempts extends Table {
  @override
  String get tableName => 'attempt';

  TextColumn get id => text()();
  TextColumn get deckId => text()();
  TextColumn get wordId => text()();

  /// The name of a `PlayMode`: matching, quiz, typing or mix.
  TextColumn get mode => text()();

  /// The name of a `WordOutcome`: firstTry, withHelp or wrongFirst.
  TextColumn get outcome => text()();

  DateTimeColumn get answeredAt => dateTime()();

  /// Whether the backend already has the row (set by the sync, card LL-30).
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  /// Whether the backend refused the row as invalid (HTTP 400). Such a row is
  /// never sent again, so it cannot block the rows behind it; it stays in the
  /// local statistics.
  BoolColumn get syncRejected => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A deck of the last word list downloaded from the backend (card LL-29).
@DataClassName('CachedDeckRow')
class CachedDecks extends Table {
  @override
  String get tableName => 'cached_deck';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// The place of the deck in the downloaded list.
  IntColumn get position => integer()();

  /// When the backend read the deck from the spreadsheet.
  DateTimeColumn get updatedAt => dateTime()();

  /// When the phone downloaded the deck.
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A word of a [CachedDecks] row.
@DataClassName('CachedWordRow')
class CachedWords extends Table {
  @override
  String get tableName => 'cached_word';

  TextColumn get deckId => text()();
  TextColumn get id => text()();

  /// The place of the word in its deck.
  IntColumn get position => integer()();

  TextColumn get english => text()();
  TextColumn get hungarian => text()();

  /// A JSON list of the accepted English texts.
  TextColumn get acceptedEnglish => text()();

  /// A JSON list of the accepted Hungarian texts.
  TextColumn get acceptedHungarian => text()();

  TextColumn get example => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {deckId, id};
}

/// The local SQLite database of the app.
@DriftDatabase(tables: [Attempts, CachedDecks, CachedWords])
class AppDatabase extends _$AppDatabase {
  /// Opens the database on [executor]; tests pass an in-memory one.
  AppDatabase(super.executor);

  /// The database file of the app, kept across restarts.
  factory AppDatabase.persistent() =>
      AppDatabase(driftDatabase(name: 'languagelearner'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(cachedDecks);
        await migrator.createTable(cachedWords);
      }
      if (from < 3) {
        await migrator.addColumn(attempts, attempts.syncRejected);
      }
    },
  );
}
