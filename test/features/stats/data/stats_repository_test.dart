import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/database/app_database.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/round_result.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/stats_repository.dart';

RoundResult _round(Map<String, WordOutcome> outcomes) => RoundResult(
  total: outcomes.length,
  firstTry: outcomes.values.where((o) => o == WordOutcome.firstTry).length,
  withHelp: outcomes.values.where((o) => o == WordOutcome.withHelp).length,
  wrongFirst: outcomes.values.where((o) => o == WordOutcome.wrongFirst).length,
  missedWords: const [],
  helpedWords: const [],
  duration: Duration.zero,
  outcomes: outcomes,
);

/// Runs the same tests on both stores.
void _tests(AttemptStore Function() createStore) {
  late AttemptStore store;
  late StatsRepository repository;
  var minute = 0;
  var idCounter = 0;

  setUp(() {
    store = createStore();
    minute = 0;
    idCounter = 0;
    repository = StatsRepository(
      store: store,
      // Every call is one minute later, so rounds have a clear order.
      now: () => DateTime.utc(2026, 10, 15, 12, minute++),
      newId: () => 'a${idCounter++}',
    );
  });

  test('a deck without answers has no summary and no stats', () async {
    expect(await repository.deckSummary('travel'), DeckSummary.empty);
    expect(await repository.wordStats('travel'), isEmpty);
  });

  test('saves the outcome of every word of a round', () async {
    await repository.saveRound(
      _round({'w1': WordOutcome.firstTry, 'w2': WordOutcome.wrongFirst}),
      deckId: 'travel',
      mode: PlayMode.quiz,
    );

    final records = await store.forDeck('travel');
    expect(records.map((r) => r.wordId), ['w1', 'w2']);
    expect(records.map((r) => r.outcome), [
      WordOutcome.firstTry,
      WordOutcome.wrongFirst,
    ]);
    expect(records.map((r) => r.mode).toSet(), {PlayMode.quiz});
    expect(records.map((r) => r.id).toSet(), hasLength(2));
    expect(records.every((r) => !r.synced), isTrue);
  });

  test('flashcards and an empty round save nothing', () async {
    await repository.saveRound(
      _round({'w1': WordOutcome.firstTry}),
      deckId: 'travel',
      mode: PlayMode.flashcards,
    );
    await repository.saveRound(
      _round({}),
      deckId: 'travel',
      mode: PlayMode.typing,
    );

    expect(await store.forDeck('travel'), isEmpty);
  });

  test('keeps the decks apart', () async {
    await repository.saveRound(
      _round({'w1': WordOutcome.firstTry}),
      deckId: 'travel',
      mode: PlayMode.quiz,
    );
    await repository.saveRound(
      _round({'w9': WordOutcome.wrongFirst}),
      deckId: 'food',
      mode: PlayMode.quiz,
    );

    expect((await repository.deckSummary('travel')).totalAnswers, 1);
    expect((await repository.wordStats('food')).single.wordId, 'w9');
  });

  test('deckSummary counts answers and the words that go first try', () async {
    await repository.saveRound(
      _round({
        'w1': WordOutcome.firstTry,
        'w2': WordOutcome.wrongFirst,
        'w3': WordOutcome.withHelp,
      }),
      deckId: 'travel',
      mode: PlayMode.typing,
    );
    // w2 gets better, w1 gets worse: only the latest answer decides.
    await repository.saveRound(
      _round({'w2': WordOutcome.firstTry, 'w1': WordOutcome.wrongFirst}),
      deckId: 'travel',
      mode: PlayMode.mix,
    );

    expect(
      await repository.deckSummary('travel'),
      const DeckSummary(
        totalAnswers: 5,
        firstTryAnswers: 2,
        wordsGoingFirstTry: 1,
      ),
    );
  });

  test('wordStats lists the hardest word first', () async {
    // After the four rounds: w1 1/4, w2 0/1, w3 2/2, w4 0/2, w5 1/3.
    Future<void> save(Map<String, WordOutcome> outcomes) => repository
        .saveRound(_round(outcomes), deckId: 'travel', mode: PlayMode.quiz);
    await save({
      'w1': WordOutcome.firstTry,
      'w2': WordOutcome.wrongFirst,
      'w3': WordOutcome.firstTry,
      'w4': WordOutcome.wrongFirst,
      'w5': WordOutcome.firstTry,
    });
    await save({
      'w1': WordOutcome.wrongFirst,
      'w3': WordOutcome.firstTry,
      'w4': WordOutcome.withHelp,
      'w5': WordOutcome.wrongFirst,
    });
    await save({'w1': WordOutcome.wrongFirst, 'w5': WordOutcome.wrongFirst});
    await save({'w1': WordOutcome.wrongFirst});

    final stats = await repository.wordStats('travel');

    expect(stats.map((s) => s.wordId), ['w4', 'w2', 'w1', 'w5', 'w3']);
    expect(stats.first, const WordStat(wordId: 'w4', firstTry: 0, total: 2));
    expect(stats.last, const WordStat(wordId: 'w3', firstTry: 2, total: 2));
  });
}

void main() {
  group('with the in-memory store', () => _tests(InMemoryAttemptStore.new));

  group('with the SQLite database', () {
    late AppDatabase database;

    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    _tests(() => DriftAttemptStore(database));
  });
}
