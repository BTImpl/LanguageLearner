import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/theme/theme_mode.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/settings/settings_repository.dart';

import '../../helpers/in_memory_key_value_store.dart';

/// Starts the settings from what [store] holds, like `main` does at app start.
Future<ProviderContainer> _start(InMemoryKeyValueStore store) async {
  final initial = await StoreSettingsRepository(store).load();
  final container = ProviderContainer(
    overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      initialSettingsProvider.overrideWithValue(initial),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SettingsNotifier', () {
    test('starts with the loaded settings', () async {
      final store = InMemoryKeyValueStore();
      await StoreSettingsRepository(store)
          .save(const AppSettings(pairsPerPage: 7));

      final container = await _start(store);

      expect(container.read(settingsProvider).pairsPerPage, 7);
    });

    test('all four settings survive a restart', () async {
      final store = InMemoryKeyValueStore();
      final first = await _start(store);
      final notifier = first.read(settingsProvider.notifier);

      await notifier.setPromptLanguage(PromptLanguage.hungarian);
      await notifier.setPairsPerPage(8);
      await notifier.setThemeChoice(ThemeChoice.light);
      await notifier.setAppLanguage(AppLanguage.hu);

      final restarted = await _start(store);
      expect(
        restarted.read(settingsProvider),
        const AppSettings(
          promptLanguage: PromptLanguage.hungarian,
          pairsPerPage: 8,
          themeChoice: ThemeChoice.light,
          appLanguage: AppLanguage.hu,
        ),
      );
    });

    test('pairsPerPage cannot go below 3 or above 8', () async {
      final container = await _start(InMemoryKeyValueStore());
      final notifier = container.read(settingsProvider.notifier);

      await notifier.setPairsPerPage(2);
      expect(container.read(settingsProvider).pairsPerPage, 3);

      await notifier.setPairsPerPage(9);
      expect(container.read(settingsProvider).pairsPerPage, 8);

      await notifier.setPairsPerPage(-5);
      expect(container.read(settingsProvider).pairsPerPage, 3);
    });

    test('the new value is visible before it is saved', () async {
      final container = await _start(InMemoryKeyValueStore());

      final saving = container
          .read(settingsProvider.notifier)
          .setThemeChoice(ThemeChoice.light);

      expect(container.read(settingsProvider).themeChoice, ThemeChoice.light);
      await saving;
    });
  });

  group('providers derived from the settings', () {
    test('the theme mode follows the theme choice', () async {
      final container = await _start(InMemoryKeyValueStore());
      expect(container.read(appThemeModeProvider), ThemeMode.dark);

      await container
          .read(settingsProvider.notifier)
          .setThemeChoice(ThemeChoice.light);

      expect(container.read(appThemeModeProvider), ThemeMode.light);
    });

    test('the locale follows the app language', () async {
      final container = await _start(InMemoryKeyValueStore());
      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(appLocaleProvider), isNull);

      await notifier.setAppLanguage(AppLanguage.hu);
      expect(container.read(appLocaleProvider), const Locale('hu'));

      await notifier.setAppLanguage(AppLanguage.en);
      expect(container.read(appLocaleProvider), const Locale('en'));

      await notifier.setAppLanguage(AppLanguage.system);
      expect(container.read(appLocaleProvider), isNull);
    });
  });

  group('the running app', () {
    Future<ProviderContainer> pumpApp(
      WidgetTester tester,
      InMemoryKeyValueStore store,
    ) async {
      final initial = await StoreSettingsRepository(store).load();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(store),
            initialSettingsProvider.overrideWithValue(initial),
          ],
          child: const LanguageLearnerApp(),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(LanguageLearnerApp)),
      );
    }

    testWidgets('changing the app language rewrites the texts', (tester) async {
      final container = await pumpApp(tester, InMemoryKeyValueStore());
      expect(find.text('Learn'), findsOneWidget);

      await container
          .read(settingsProvider.notifier)
          .setAppLanguage(AppLanguage.hu);
      await tester.pumpAndSettle();

      expect(find.text('Tanulás'), findsOneWidget);
      expect(find.text('Learn'), findsNothing);
    });

    testWidgets('changing the theme recolors the app', (tester) async {
      final container = await pumpApp(tester, InMemoryKeyValueStore());
      Color background() =>
          Theme.of(tester.element(find.byType(HomeScreen)))
              .scaffoldBackgroundColor;
      expect(background(), const Color(0xFF0A1226));

      await container
          .read(settingsProvider.notifier)
          .setThemeChoice(ThemeChoice.light);
      await tester.pumpAndSettle();

      expect(background(), const Color(0xFFF2F4FB));
    });

    testWidgets('starts with the saved settings, without a flash', (
      tester,
    ) async {
      final store = InMemoryKeyValueStore();
      await StoreSettingsRepository(store).save(
        const AppSettings(
          themeChoice: ThemeChoice.light,
          appLanguage: AppLanguage.hu,
        ),
      );

      await pumpApp(tester, store);

      expect(find.text('Tanulás'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(HomeScreen))).brightness,
        Brightness.light,
      );
    });
  });
}
