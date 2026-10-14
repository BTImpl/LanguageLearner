import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/data/fake_word_repository.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';

/// The source of the decks. Override this one provider to swap the source,
/// e.g. for the backend (card LL-28) or in tests.
final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => const FakeWordRepository(),
);

/// All decks of the student.
final decksProvider = FutureProvider<List<Deck>>(
  (ref) => ref.watch(wordRepositoryProvider).getDecks(),
);

/// The id of the deck the student picked, `null` while nothing is picked.
final selectedDeckIdProvider = NotifierProvider<SelectedDeckId, String?>(
  SelectedDeckId.new,
);

class SelectedDeckId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
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
