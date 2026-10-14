import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/data/fake_word_repository.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/key_value_store.dart';

/// The source of the decks. Override this one provider to swap the source,
/// e.g. for the backend (card LL-28) or in tests.
final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => FakeWordRepository(now: ref.watch(clockProvider)),
);

/// All decks of the student.
final decksProvider = FutureProvider<List<Deck>>(
  (ref) => ref.watch(wordRepositoryProvider).getDecks(),
);

/// The key of the picked deck id in the [KeyValueStore].
const selectedDeckIdKey = 'selectedDeckId';

/// The deck id saved by an earlier run, loaded before the first frame.
/// `main` overrides this; `null` means nothing was saved.
final initialSelectedDeckIdProvider = Provider<String?>((ref) => null);

/// The id of the deck the student picked, `null` while nothing is picked.
/// The pick is saved and survives an app restart.
final selectedDeckIdProvider = NotifierProvider<SelectedDeckId, String?>(
  SelectedDeckId.new,
);

class SelectedDeckId extends Notifier<String?> {
  @override
  String? build() => ref.watch(initialSelectedDeckIdProvider);

  void select(String id) {
    state = id;
    unawaited(_save(id));
  }

  // A storage problem must not break the pick: it just won't be remembered.
  Future<void> _save(String id) async {
    try {
      await ref.read(keyValueStoreProvider).setString(selectedDeckIdKey, id);
    } on Exception {
      // Ignored on purpose, see above.
    }
  }
}

/// The deck the games use: the picked one, or the first deck while nothing
/// valid is picked. Data is `null` when there are no decks at all.
final selectedDeckProvider = Provider<AsyncValue<Deck?>>((ref) {
  final selectedId = ref.watch(selectedDeckIdProvider);
  return ref.watch(decksProvider).whenData((decks) {
    for (final deck in decks) {
      if (deck.id == selectedId) {
        return deck;
      }
    }
    return decks.firstOrNull;
  });
});

/// When the words were last read from the spreadsheet: the latest `updatedAt`
/// of the decks, `null` while there are no decks.
final lastUpdatedProvider = Provider<DateTime?>((ref) {
  final decks = ref.watch(decksProvider).value;
  if (decks == null || decks.isEmpty) {
    return null;
  }
  return decks
      .map((deck) => deck.updatedAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
});

/// Reads the decks again from the source and reloads them. Throws if that
/// fails.
final refreshWordsProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await ref.read(wordRepositoryProvider).refresh();
    ref.invalidate(decksProvider);
    await ref.read(decksProvider.future);
  },
);
