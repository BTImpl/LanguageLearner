import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';

var _id = 0;

AttemptRecord _attempt(
  String deckId,
  String wordId,
  WordOutcome outcome, {
  int minute = 0,
}) => AttemptRecord(
  id: 'a${_id++}',
  deckId: deckId,
  wordId: wordId,
  mode: PlayMode.quiz,
  outcome: outcome,
  answeredAt: DateTime.utc(2026, 10, 15, 12, minute),
);

Future<(GoRouter, ProviderContainer)> _openStats(
  WidgetTester tester, {
  required InMemoryAttemptStore store,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createAppRouter();
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(router),
      appLocaleProvider.overrideWithValue(locale),
      attemptStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LanguageLearnerApp(),
    ),
  );
  router.go(AppRoutes.stats);
  await tester.pumpAndSettle();
  return (router, container);
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('shows the empty state before the first round', (tester) async {
    final (router, _) = await _openStats(tester, store: InMemoryAttemptStore());

    expect(find.text('Statistics'), findsWidgets);
    expect(
      find.text(
        'You will see here which words go well. '
        'Start a round on the Learn tab.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('words go right first time'), findsNothing);

    await tester.tap(find.text('Start practicing'));
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.home);
  });

  testWidgets('shows the summary and the words, hardest first', (tester) async {
    final store = InMemoryAttemptStore();
    await store.insertAll([
      // boarding pass (travel-1): 1 of 3 right first time, the latest wrong.
      _attempt('travel', 'travel-1', WordOutcome.firstTry),
      _attempt('travel', 'travel-1', WordOutcome.wrongFirst, minute: 1),
      _attempt('travel', 'travel-1', WordOutcome.wrongFirst, minute: 2),
      // luggage (travel-2): 2 of 2, so it goes first try.
      _attempt('travel', 'travel-2', WordOutcome.firstTry),
      _attempt('travel', 'travel-2', WordOutcome.firstTry, minute: 1),
      // departure (travel-3): 0 of 1.
      _attempt('travel', 'travel-3', WordOutcome.wrongFirst),
      // Another deck must not show up.
      _attempt('restaurant', 'restaurant-1', WordOutcome.firstTry),
    ]);

    await _openStats(tester, store: store);

    expect(find.text('1 of 12 words go right first time'), findsOneWidget);
    expect(find.text('6 answers in total, 3 right first time'), findsOneWidget);
    expect(find.text('Words, hardest first'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);

    final departure = tester.getTopLeft(find.text('departure')).dy;
    final boardingPass = tester.getTopLeft(find.text('boarding pass')).dy;
    final luggage = tester.getTopLeft(find.text('luggage')).dy;
    expect(departure, lessThan(boardingPass));
    expect(boardingPass, lessThan(luggage));
  });

  testWidgets('lists the words nobody answered at the end', (tester) async {
    final store = InMemoryAttemptStore();
    await store.insertAll([
      _attempt('travel', 'travel-1', WordOutcome.firstTry),
    ]);

    await _openStats(tester, store: store);
    await tester.scrollUntilVisible(
      find.text('seat'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('not practiced yet'), findsWidgets);
    final answered = tester.getTopLeft(find.text('boarding pass')).dy;
    final unanswered = tester.getTopLeft(find.text('seat')).dy;
    expect(answered, lessThan(unanswered));
  });

  testWidgets('is shown in Hungarian', (tester) async {
    final store = InMemoryAttemptStore();
    await store.insertAll([
      _attempt('travel', 'travel-2', WordOutcome.firstTry),
    ]);

    await _openStats(tester, store: store, locale: const Locale('hu'));

    expect(find.text('12 szóból 1 megy elsőre'), findsOneWidget);
    expect(find.text('1 válasz összesen, ebből 1 elsőre jó'), findsOneWidget);
    expect(find.text('Szavak, a legnehezebbtől'), findsOneWidget);
  });

  testWidgets('follows the deck picked in the deck picker', (tester) async {
    final store = InMemoryAttemptStore();
    await store.insertAll([
      _attempt('travel', 'travel-1', WordOutcome.firstTry),
      _attempt('restaurant', 'restaurant-1', WordOutcome.wrongFirst),
      _attempt('restaurant', 'restaurant-2', WordOutcome.wrongFirst),
    ]);
    await _openStats(tester, store: store);
    expect(find.text('1 of 12 words go right first time'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étterem').last);
    await tester.pumpAndSettle();

    expect(find.text('0 of 5 words go right first time'), findsOneWidget);
    expect(find.text('2 answers in total, 0 right first time'), findsOneWidget);
  });

  testWidgets('updates when a round is saved, without a restart', (
    tester,
  ) async {
    final store = InMemoryAttemptStore();
    final (_, container) = await _openStats(tester, store: store);
    expect(find.text('Start practicing'), findsOneWidget);

    await store.insertAll([
      _attempt('travel', 'travel-1', WordOutcome.firstTry),
    ]);
    container.read(statsRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();

    expect(find.text('Start practicing'), findsNothing);
    expect(find.text('1 of 12 words go right first time'), findsOneWidget);
  });
}
