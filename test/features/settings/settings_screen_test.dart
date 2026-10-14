import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/settings/settings_repository.dart';
import 'package:languagelearner/features/settings/settings_screen.dart';

import '../../helpers/in_memory_key_value_store.dart';

final _now = DateTime(2026, 10, 14, 15, 30);

/// Opens the settings tab of the app with [saved] as the stored settings.
Future<(InMemoryKeyValueStore, ProviderContainer)> _openSettings(
  WidgetTester tester, {
  AppSettings saved = const AppSettings(),
}) async {
  // Tall enough to show the whole screen without scrolling.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = InMemoryKeyValueStore();
  await StoreSettingsRepository(store).save(saved);
  final router = createAppRouter(initialLocation: AppRoutes.settings);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        initialSettingsProvider.overrideWithValue(saved),
        routerProvider.overrideWithValue(router),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LanguageLearnerApp)),
  );
  return (store, container);
}

// The context must be below the MaterialApp, which provides the theme.
Color _background(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SettingsScreen)))
        .scaffoldBackgroundColor;

IconButton _stepper(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.widgetWithIcon(
        IconButton,
        tooltip == 'More pairs' ? Icons.add : Icons.remove,
      ),
    );

void main() {
  testWidgets('shows every card with the stored settings', (tester) async {
    await _openSettings(tester);

    expect(find.text('Settings'), findsNWidgets(2)); // title + bottom tab
    expect(find.text('Kiss Anna'), findsOneWidget);
    expect(find.text('KA'), findsOneWidget);
    expect(find.text('kiss.anna@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Which language should it ask in?'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('Pairs per page'), findsOneWidget);
    expect(find.text('In matching, between 3 and 8'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Refresh word list'), findsOneWidget);
    expect(find.text('btimpl.eu'), findsOneWidget);
  });

  testWidgets('the asking language is switched and its hint follows', (
    tester,
  ) async {
    final (store, container) = await _openSettings(tester);
    expect(
      find.text('You see the English word, you need to know the Hungarian.'),
      findsOneWidget,
    );

    await tester.tap(find.text('In Hungarian'));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).promptLanguage,
      PromptLanguage.hungarian,
    );
    expect(
      find.text('You see the Hungarian word, you need to know the English.'),
      findsOneWidget,
    );
    expect(
      (await StoreSettingsRepository(store).load()).promptLanguage,
      PromptLanguage.hungarian,
    );
  });

  testWidgets('the three-state app language rewrites the labels', (
    tester,
  ) async {
    final (store, container) = await _openSettings(tester);

    await tester.tap(find.text('Magyar'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).appLanguage, AppLanguage.hu);
    expect(find.text('Beállítások'), findsNWidgets(2));
    expect(find.text('Az app nyelve'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    // The language names are not translated.
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Magyar'), findsOneWidget);
    expect(find.text('Rendszer'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).appLanguage, AppLanguage.en);
    expect(find.text('Settings'), findsNWidgets(2));
    expect(find.text('App language'), findsOneWidget);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).appLanguage, AppLanguage.system);
    expect(
      (await StoreSettingsRepository(store).load()).appLanguage,
      AppLanguage.system,
    );
  });

  testWidgets('the pairs per page stepper stops at 3 and 8', (tester) async {
    final (_, container) = await _openSettings(tester);
    int pairs() => container.read(settingsProvider).pairsPerPage;

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('More pairs'));
      await tester.pumpAndSettle();
    }
    expect(pairs(), 8);
    expect(find.text('8'), findsOneWidget);
    expect(_stepper(tester, 'More pairs').onPressed, isNull);
    expect(_stepper(tester, 'Fewer pairs').onPressed, isNotNull);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('Fewer pairs'));
      await tester.pumpAndSettle();
    }
    expect(pairs(), 3);
    expect(find.text('3'), findsOneWidget);
    expect(_stepper(tester, 'Fewer pairs').onPressed, isNull);
    expect(_stepper(tester, 'More pairs').onPressed, isNotNull);
  });

  testWidgets('the theme is switched at once', (tester) async {
    final (store, _) = await _openSettings(tester);
    expect(_background(tester), const Color(0xFF0A1226));

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(_background(tester), const Color(0xFFF2F4FB));
    expect(
      (await StoreSettingsRepository(store).load()).themeChoice,
      ThemeChoice.light,
    );

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(_background(tester), const Color(0xFF0A1226));
  });

  testWidgets('the screen shows the settings saved before a restart', (
    tester,
  ) async {
    await _openSettings(
      tester,
      saved: const AppSettings(
        promptLanguage: PromptLanguage.hungarian,
        pairsPerPage: 7,
        themeChoice: ThemeChoice.light,
        appLanguage: AppLanguage.hu,
      ),
    );

    expect(find.text('Melyik nyelven kérdezzen?'), findsOneWidget);
    expect(
      find.text('A magyar szót látod, az angolt kell tudnod.'),
      findsOneWidget,
    );
    expect(find.text('7'), findsOneWidget);
    expect(_background(tester), const Color(0xFFF2F4FB));
  });

  testWidgets('refreshing the word list updates the time', (tester) async {
    await _openSettings(tester);
    expect(find.textContaining('Last updated'), findsOneWidget);
    expect(find.textContaining('today'), findsNothing);

    await tester.tap(find.text('Refresh word list'));
    await tester.pumpAndSettle();

    expect(find.text('Last updated today at 15:30'), findsOneWidget);
  });

  testWidgets('the refresh time is written in Hungarian too', (tester) async {
    await _openSettings(
      tester,
      saved: const AppSettings(appLanguage: AppLanguage.hu),
    );

    await tester.tap(find.text('Szólista frissítése'));
    await tester.pumpAndSettle();

    expect(find.text('Utoljára ma 15:30-kor'), findsOneWidget);
  });

  testWidgets('the cards are labeled and big enough to tap', (tester) async {
    final handle = tester.ensureSemantics();
    await _openSettings(tester);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
