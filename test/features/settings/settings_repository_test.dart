import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_repository.dart';

import '../../helpers/in_memory_key_value_store.dart';

void main() {
  test('loads the defaults when nothing was saved', () async {
    final repository = StoreSettingsRepository(InMemoryKeyValueStore());

    expect(await repository.load(), const AppSettings());
  });

  test('loads what was saved, also from a new repository', () async {
    final store = InMemoryKeyValueStore();
    const settings = AppSettings(
      promptLanguage: PromptLanguage.hungarian,
      pairsPerPage: 7,
      themeChoice: ThemeChoice.light,
      appLanguage: AppLanguage.hu,
    );

    await StoreSettingsRepository(store).save(settings);

    expect(await StoreSettingsRepository(store).load(), settings);
  });

  test('every setting is saved on its own', () async {
    for (final settings in const [
      AppSettings(promptLanguage: PromptLanguage.hungarian),
      AppSettings(pairsPerPage: 8),
      AppSettings(themeChoice: ThemeChoice.light),
      AppSettings(appLanguage: AppLanguage.en),
    ]) {
      final store = InMemoryKeyValueStore();
      await StoreSettingsRepository(store).save(settings);

      expect(await StoreSettingsRepository(store).load(), settings);
    }
  });

  test('a saved value that is not valid gives the default', () async {
    final repository = StoreSettingsRepository(
      InMemoryKeyValueStore({
        StoreSettingsRepository.promptLanguageKey: 'klingon',
        StoreSettingsRepository.themeChoiceKey: 'sepia',
        StoreSettingsRepository.appLanguageKey: 'de',
      }),
    );

    expect(await repository.load(), const AppSettings());
  });

  test('a saved pairsPerPage outside 3..8 is brought into range', () async {
    Future<int> load(int stored) async {
      final repository = StoreSettingsRepository(
        InMemoryKeyValueStore({
          StoreSettingsRepository.pairsPerPageKey: stored,
        }),
      );
      return (await repository.load()).pairsPerPage;
    }

    expect(await load(0), 3);
    expect(await load(2), 3);
    expect(await load(9), 8);
    expect(await load(100), 8);
    expect(await load(6), 6);
  });
}
