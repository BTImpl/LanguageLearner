import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/shell/app_bottom_nav.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/settings/settings_screen.dart';
import 'package:languagelearner/features/stats/stats_screen.dart';

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  String location = AppRoutes.home,
  Locale locale = const Locale('en'),
}) async {
  final router = createAppRouter(initialLocation: location);
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
  return router;
}

String _location(GoRouter router) =>
    router.routeInformationProvider.value.uri.path;

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(AppBottomNav), matching: find.text(label));

void main() {
  testWidgets('starts on the Learn tab with the bottom navigation', (
    tester,
  ) async {
    final router = await _pumpApp(tester);

    expect(_location(router), AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(_navLabel('Learn'), findsOneWidget);
    expect(_navLabel('Statistics'), findsOneWidget);
    expect(_navLabel('Settings'), findsOneWidget);
  });

  testWidgets('the tabs are switched from the bottom navigation', (
    tester,
  ) async {
    final router = await _pumpApp(tester);

    await tester.tap(_navLabel('Statistics'));
    await tester.pumpAndSettle();
    expect(_location(router), AppRoutes.stats);
    expect(find.byType(StatsScreen), findsOneWidget);

    await tester.tap(_navLabel('Settings'));
    await tester.pumpAndSettle();
    expect(_location(router), AppRoutes.settings);
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(_navLabel('Learn'));
    await tester.pumpAndSettle();
    expect(_location(router), AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the bottom navigation is localized', (tester) async {
    await _pumpApp(tester, locale: const Locale('hu'));

    expect(_navLabel('Tanulás'), findsOneWidget);
    expect(_navLabel('Statisztika'), findsOneWidget);
    expect(_navLabel('Beállítások'), findsOneWidget);
  });

  const expectedTitles = <PlayMode, String>{
    PlayMode.flashcards: 'Flashcards',
    PlayMode.matching: 'Matching',
    PlayMode.quiz: 'Quiz',
    PlayMode.typing: 'Exact match',
    PlayMode.mix: 'Mix',
  };

  for (final mode in PlayMode.values) {
    testWidgets('/play/${mode.name} has no bottom navigation', (tester) async {
      final router = await _pumpApp(tester, location: AppRoutes.play(mode));

      expect(_location(router), '/play/${mode.name}');
      expect(find.text(expectedTitles[mode]!), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
    });

    testWidgets('/play/${mode.name}/summary has no bottom navigation', (
      tester,
    ) async {
      final router = await _pumpApp(tester, location: AppRoutes.summary(mode));

      expect(_location(router), '/play/${mode.name}/summary');
      expect(find.text('Round complete'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
    });
  }

  testWidgets('the back button of a game leads to the home screen', (
    tester,
  ) async {
    final router = await _pumpApp(
      tester,
      location: AppRoutes.play(PlayMode.quiz),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(_location(router), AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('the back button of a round end leads to the home screen', (
    tester,
  ) async {
    final router = await _pumpApp(
      tester,
      location: AppRoutes.summary(PlayMode.matching),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(_location(router), AppRoutes.home);
  });
}
