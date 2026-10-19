import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/key_value_store.dart';

import '../../helpers/in_memory_key_value_store.dart';

class _StubRepository implements WordRepository {
  @override
  Future<void> clearLocal() async {}

  _StubRepository(this.decks);

  final List<Deck> decks;
  var refreshes = 0;

  @override
  Future<List<Deck>> getDecks() async => decks;

  @override
  Future<void> refresh() async => refreshes++;
}

Deck _deck(String id) => Deck(
  id: id,
  name: 'Deck $id',
  updatedAt: DateTime.utc(2026),
  words: [WordPair.fromCells(id: '$id-1', english: 'a', hungarian: 'b')],
);

ProviderContainer _container({WordRepository? repository}) {
  final container = ProviderContainer(
    overrides: [
      if (repository != null)
        wordRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('uses the built-in decks by default', () async {
    final container = _container();

    final decks = await container.read(decksProvider.future);

    expect(decks.map((deck) => deck.id), ['travel', 'restaurant']);
  });

  test('the repository is swapped by overriding one provider', () async {
    final container = _container(
      repository: _StubRepository([_deck('x'), _deck('y')]),
    );

    final decks = await container.read(decksProvider.future);

    expect(decks.map((deck) => deck.id), ['x', 'y']);
  });

  test('the first deck is selected until another one is picked', () async {
    final container = _container(
      repository: _StubRepository([_deck('x'), _deck('y')]),
    );
    await container.read(decksProvider.future);

    expect(container.read(selectedDeckProvider).value?.id, 'x');

    container.read(selectedDeckIdProvider.notifier).select('y');

    expect(container.read(selectedDeckProvider).value?.id, 'y');
  });

  test('an unknown picked deck falls back to the first one', () async {
    final container = _container(
      repository: _StubRepository([_deck('x'), _deck('y')]),
    );
    await container.read(decksProvider.future);

    container.read(selectedDeckIdProvider.notifier).select('gone');

    expect(container.read(selectedDeckProvider).value?.id, 'x');
  });

  test('there is no selected deck when there are no decks', () async {
    final container = _container(repository: _StubRepository([]));
    await container.read(decksProvider.future);

    final selected = container.read(selectedDeckProvider);

    expect(selected.hasValue, isTrue);
    expect(selected.value, isNull);
  });

  test('the picked deck is saved and loaded back after a restart', () async {
    final store = InMemoryKeyValueStore();
    final first = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(first.dispose);

    first.read(selectedDeckIdProvider.notifier).select('y');
    await Future<void>.delayed(Duration.zero);

    expect(store.values[selectedDeckIdKey], 'y');

    final restarted = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        initialSelectedDeckIdProvider.overrideWithValue(
          await store.getString(selectedDeckIdKey),
        ),
      ],
    );
    addTearDown(restarted.dispose);

    expect(restarted.read(selectedDeckIdProvider), 'y');
  });
}
