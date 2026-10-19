import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/data/word_repository.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/home/widgets/deck_picker_sheet.dart';

import '../../helpers/in_memory_key_value_store.dart';

class _SingleDeckRepository implements WordRepository {
  @override
  Future<void> clearLocal() async {}

  @override
  Future<List<Deck>> getDecks() async => [
    Deck(
      id: 'only',
      name: 'Only deck',
      updatedAt: DateTime.utc(2026),
      words: [WordPair.fromCells(id: 'w', english: 'a', hungarian: 'b')],
    ),
  ];

  @override
  Future<void> refresh() async {}
}

Future<InMemoryKeyValueStore> _openHome(
  WidgetTester tester, {
  String? saved,
  WordRepository? repository,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = InMemoryKeyValueStore({selectedDeckIdKey: ?saved});
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        keyValueStoreProvider.overrideWithValue(store),
        initialSelectedDeckIdProvider.overrideWithValue(saved),
        if (repository != null)
          wordRepositoryProvider.overrideWithValue(repository),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Finder _inSheet(String text) => find.descendant(
  of: find.byType(DeckPickerSheet),
  matching: find.text(text),
);

Future<void> _openPicker(WidgetTester tester, String cardTitle) async {
  await tester.tap(find.text(cardTitle));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens from the deck card with the decks sorted by name', (
    tester,
  ) async {
    await _openHome(tester);
    await _openPicker(tester, 'Utazás');

    expect(find.text('Pick a deck'), findsOneWidget);
    expect(_inSheet('Étterem'), findsOneWidget);
    expect(_inSheet('Utazás'), findsOneWidget);
    expect(
      tester.getTopLeft(_inSheet('Étterem')).dy,
      lessThan(tester.getTopLeft(_inSheet('Utazás')).dy),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('picking a deck shows it on the card and saves it', (
    tester,
  ) async {
    final store = await _openHome(tester);
    await _openPicker(tester, 'Utazás');

    await tester.tap(_inSheet('Étterem'));
    await tester.pumpAndSettle();

    expect(find.byType(DeckPickerSheet), findsNothing);
    expect(find.text('Étterem'), findsOneWidget);
    expect(find.text('Utazás'), findsNothing);
    expect(store.values[selectedDeckIdKey], 'restaurant');
  });

  testWidgets('the saved deck is selected after a restart', (tester) async {
    await _openHome(tester, saved: 'restaurant');

    expect(find.text('Étterem'), findsOneWidget);
    expect(find.text('Utazás'), findsNothing);
  });

  testWidgets('a saved deck that no longer exists falls back to the first', (
    tester,
  ) async {
    await _openHome(tester, saved: 'gone');

    expect(find.text('Utazás'), findsOneWidget);
  });

  testWidgets('a single deck can be opened and is shown as selected', (
    tester,
  ) async {
    await _openHome(tester, repository: _SingleDeckRepository());
    await _openPicker(tester, 'Only deck');

    expect(_inSheet('Only deck'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  group('closing without picking keeps the selection', () {
    Future<void> expectUnchanged(
      WidgetTester tester,
      InMemoryKeyValueStore store,
    ) async {
      expect(find.byType(DeckPickerSheet), findsNothing);
      expect(find.text('Utazás'), findsOneWidget);
      expect(store.values, isEmpty);
    }

    testWidgets('with the close button', (tester) async {
      final store = await _openHome(tester);
      await _openPicker(tester, 'Utazás');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await expectUnchanged(tester, store);
    });

    testWidgets('by tapping the scrim', (tester) async {
      final store = await _openHome(tester);
      await _openPicker(tester, 'Utazás');

      await tester.tapAt(const Offset(195, 20));
      await tester.pumpAndSettle();

      await expectUnchanged(tester, store);
    });

    testWidgets('by dragging the sheet down', (tester) async {
      final store = await _openHome(tester);
      await _openPicker(tester, 'Utazás');

      await tester.fling(find.text('Pick a deck'), const Offset(0, 600), 2000);
      await tester.pumpAndSettle();

      await expectUnchanged(tester, store);
    });
  });
}
