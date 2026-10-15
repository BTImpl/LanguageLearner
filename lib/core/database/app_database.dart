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

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The local SQLite database of the app.
@DriftDatabase(tables: [Attempts])
class AppDatabase extends _$AppDatabase {
  /// Opens the database on [executor]; tests pass an in-memory one.
  AppDatabase(super.executor);

  /// The database file of the app, kept across restarts.
  factory AppDatabase.persistent() =>
      AppDatabase(driftDatabase(name: 'languagelearner'));

  @override
  int get schemaVersion => 1;
}
