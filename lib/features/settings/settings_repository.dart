import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/settings/app_settings.dart';

/// Loads and saves the [AppSettings].
abstract interface class SettingsRepository {
  /// The saved settings; a setting that was never saved (or whose saved value
  /// is not valid) has its default.
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

/// [SettingsRepository] that keeps one entry per setting in a [KeyValueStore].
class StoreSettingsRepository implements SettingsRepository {
  const StoreSettingsRepository(this._store);

  static const promptLanguageKey = 'settings.promptLanguage';
  static const pairsPerPageKey = 'settings.pairsPerPage';
  static const themeChoiceKey = 'settings.themeChoice';
  static const appLanguageKey = 'settings.appLanguage';

  final KeyValueStore _store;

  @override
  Future<AppSettings> load() async {
    const defaults = AppSettings();
    final pairsPerPage = await _store.getInt(pairsPerPageKey);
    return AppSettings(
      promptLanguage: _byName(
        PromptLanguage.values,
        await _store.getString(promptLanguageKey),
        defaults.promptLanguage,
      ),
      pairsPerPage: (pairsPerPage ?? defaults.pairsPerPage).clamp(
        AppSettings.minPairsPerPage,
        AppSettings.maxPairsPerPage,
      ),
      themeChoice: _byName(
        ThemeChoice.values,
        await _store.getString(themeChoiceKey),
        defaults.themeChoice,
      ),
      appLanguage: _byName(
        AppLanguage.values,
        await _store.getString(appLanguageKey),
        defaults.appLanguage,
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _store.setString(promptLanguageKey, settings.promptLanguage.name);
    await _store.setInt(pairsPerPageKey, settings.pairsPerPage);
    await _store.setString(themeChoiceKey, settings.themeChoice.name);
    await _store.setString(appLanguageKey, settings.appLanguage.name);
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}
