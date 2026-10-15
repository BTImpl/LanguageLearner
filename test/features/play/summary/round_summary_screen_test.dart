import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/features/play/summary/round_summary_screen.dart';

RoundSummaryData _data({
  int tiles = 3,
  List<ReviewWord> review = const [
    ReviewWord(prompt: 'delay', answer: 'késés'),
    ReviewWord(prompt: 'ticket', answer: 'jegy'),
  ],
}) => RoundSummaryData(
  modeName: 'Quiz',
  deckName: 'Utazás',
  headline: '9 of 12 words right first time',
  stats: [
    const SummaryStat(
      value: '9',
      label: 'right first time',
      tone: StatTone.success,
    ),
    const SummaryStat(
      value: '3',
      label: 'wrong first time',
      tone: StatTone.error,
    ),
    if (tiles == 3) const SummaryStat(value: '2', label: 'minutes'),
  ],
  reviewWords: review,
  restartLabel: 'Restart Quiz',
  restartLocation: AppRoutes.play(PlayMode.quiz),
);

Future<GoRouter> _open(
  WidgetTester tester,
  RoundSummaryData data, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
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
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  router.go(AppRoutes.summary(PlayMode.quiz), extra: data);
  await tester.pumpAndSettle();
  return router;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('shows the head card, three tiles and the word list', (
    tester,
  ) async {
    await _open(tester, _data());

    expect(find.byType(RoundSummaryScreen), findsOneWidget);
    expect(find.text('Quiz, Utazás'), findsOneWidget);
    expect(find.text('Round complete'), findsOneWidget);
    expect(find.text('9 of 12 words right first time'), findsOneWidget);
    expect(find.byType(StatTile), findsNWidgets(3));
    expect(find.text('Worth another look'), findsOneWidget);
    expect(find.text('delay'), findsOneWidget);
    expect(find.text('késés'), findsOneWidget);
  });

  testWidgets('shows two tiles and no list without words', (tester) async {
    await _open(tester, _data(tiles: 2, review: const []));

    expect(find.byType(StatTile), findsNWidgets(2));
    expect(find.text('Worth another look'), findsNothing);
  });

  testWidgets('the restart button opens the game route of the mode', (
    tester,
  ) async {
    final router = await _open(tester, _data());

    await tester.tap(find.text('Restart Quiz'));
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.play(PlayMode.quiz));
  });

  testWidgets('the back button goes to the home screen', (tester) async {
    final router = await _open(tester, _data());

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the close button goes to the home screen', (tester) async {
    final router = await _open(tester, _data());

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.home);
  });

  testWidgets('the system back goes to the home screen', (tester) async {
    final router = await _open(tester, _data());

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(_path(router), AppRoutes.home);
  });

  testWidgets('a long word list scrolls and keeps the buttons visible', (
    tester,
  ) async {
    final review = [
      for (var i = 0; i < 30; i++)
        ReviewWord(prompt: 'word $i', answer: 'szó $i'),
    ];
    await _open(tester, _data(review: review), size: const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('Restart Quiz'), findsOneWidget);
    // The list is built completely, but the last word starts below the screen.
    expect(tester.getTopLeft(find.text('word 29')).dy, greaterThan(640));

    await tester.scrollUntilVisible(
      find.text('word 29'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.getBottomLeft(find.text('word 29')).dy, lessThan(640));
    expect(tester.getTopLeft(find.text('Back to home')).dy, lessThan(640));
  });

  testWidgets('has Hungarian texts', (tester) async {
    await _open(tester, _data(), locale: const Locale('hu'));

    expect(find.text('Kör vége'), findsOneWidget);
    expect(find.text('Ezeket érdemes újra átnézni'), findsOneWidget);
    expect(find.text('Vissza a kezdőlapra'), findsOneWidget);
  });

  testWidgets('meets the tap target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _data());

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
