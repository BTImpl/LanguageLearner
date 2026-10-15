import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';

final _now = DateTime(2026, 10, 14, 15, 30);

Future<GoRouter> _openHome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 1400),
  AttemptStore? attempts,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        appLocaleProvider.overrideWithValue(locale),
        clockProvider.overrideWithValue(() => _now),
        if (attempts != null) attemptStoreProvider.overrideWithValue(attempts),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('shows header, headline, deck card and all mode tiles', (
    tester,
  ) async {
    await _openHome(tester);

    expect(find.text('LanguageLearner'), findsOneWidget);
    expect(find.text('What shall we practice today?'), findsOneWidget);
    expect(find.text('KA'), findsOneWidget);
    expect(find.textContaining('12 words, updated'), findsOneWidget);
    expect(find.text('Not practiced yet'), findsOneWidget);
    expect(find.text('Mix'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Flip and listen'), findsOneWidget);
  });

  testWidgets('is shown in Hungarian', (tester) async {
    await _openHome(tester, locale: const Locale('hu'));

    expect(find.text('Mit gyakorolunk ma?'), findsOneWidget);
    expect(find.text('Keresd meg a párját'), findsOneWidget);
    expect(find.text('Még nem gyakoroltad'), findsOneWidget);
  });

  group('deck progress', () {
    AttemptRecord attempt(String wordId, WordOutcome outcome, int minute) =>
        AttemptRecord(
          id: '$wordId-$minute',
          deckId: 'travel',
          wordId: wordId,
          mode: PlayMode.quiz,
          outcome: outcome,
          answeredAt: DateTime.utc(2026, 10, 14, 12, minute),
        );

    testWidgets('shows the words that go first try', (tester) async {
      final store = InMemoryAttemptStore();
      await store.insertAll([
        attempt('travel-1', WordOutcome.firstTry, 0),
        attempt('travel-2', WordOutcome.firstTry, 0),
        attempt('travel-3', WordOutcome.wrongFirst, 0),
        // travel-2 slipped in its latest answer, so it no longer counts.
        attempt('travel-2', WordOutcome.wrongFirst, 1),
      ]);

      await _openHome(tester, attempts: store);

      expect(find.text('1 right first time'), findsOneWidget);
      expect(find.text('Not practiced yet'), findsNothing);
    });

    testWidgets('updates when a round is saved', (tester) async {
      final store = InMemoryAttemptStore();
      await _openHome(tester, attempts: store);
      expect(find.text('Not practiced yet'), findsOneWidget);

      await store.insertAll([attempt('travel-1', WordOutcome.firstTry, 0)]);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LanguageLearnerApp)),
      );
      container.read(statsRevisionProvider.notifier).bump();
      await tester.pumpAndSettle();

      expect(find.text('1 right first time'), findsOneWidget);
    });
  });

  testWidgets('refresh shows the update time of today', (tester) async {
    await _openHome(tester);

    await tester.tap(find.byTooltip('Refresh word list'));
    await tester.pumpAndSettle();

    expect(find.text('12 words, updated today at 15:30'), findsOneWidget);
  });

  const tiles = <(String, String)>[
    ('Mix', '/play/mix'),
    ('Flashcards', '/play/flashcards'),
    ('Matching', '/play/matching'),
    ('Quiz', '/play/quiz'),
    ('Exact match', '/play/typing'),
  ];
  for (final (title, path) in tiles) {
    testWidgets('tapping $title opens $path', (tester) async {
      final route = await _openHome(tester);

      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();

      expect(_path(route), path);
    });
  }

  testWidgets('tapping the monogram opens the settings', (tester) async {
    final route = await _openHome(tester);

    await tester.tap(find.text('KA'));
    await tester.pumpAndSettle();

    expect(_path(route), AppRoutes.settings);
  });

  testWidgets('fits a 360 px wide phone by scrolling', (tester) async {
    await _openHome(tester, size: const Size(360, 640));

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Exact match'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Exact match'), findsOneWidget);
  });

  testWidgets('meets the tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _openHome(tester);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
