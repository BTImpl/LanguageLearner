import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/email_validator.dart';

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
  static const typingAttemptsKey = 'settings.typingAttempts';
  static const teacherEmailKey = 'settings.teacherEmail';
  static const speakingHintsKey = 'settings.speakingHints';
  static const mixSpeakingKey = 'settings.mixSpeaking';

  final KeyValueStore _store;

  @override
  Future<AppSettings> load() async {
    const defaults = AppSettings();
    final pairsPerPage = await _store.getInt(pairsPerPageKey);
    final typingAttempts = await _store.getInt(typingAttemptsKey);
    final teacherEmail = (await _store.getString(teacherEmailKey))?.trim();
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
      typingAttempts: (typingAttempts ?? defaults.typingAttempts).clamp(
        AppSettings.minTypingAttempts,
        AppSettings.maxTypingAttempts,
      ),
      // A saved text that is not an address (it cannot come from the app) is
      // taken as no address.
      teacherEmail: teacherEmail != null && isValidEmail(teacherEmail)
          ? teacherEmail
          : defaults.teacherEmail,
      speakingHints: _flag(
        await _store.getInt(speakingHintsKey),
        defaults.speakingHints,
      ),
      mixSpeaking: _flag(
        await _store.getInt(mixSpeakingKey),
        defaults.mixSpeaking,
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _store.setString(promptLanguageKey, settings.promptLanguage.name);
    await _store.setInt(pairsPerPageKey, settings.pairsPerPage);
    await _store.setString(themeChoiceKey, settings.themeChoice.name);
    await _store.setString(appLanguageKey, settings.appLanguage.name);
    await _store.setInt(typingAttemptsKey, settings.typingAttempts);
    await _store.setString(teacherEmailKey, settings.teacherEmail);
    await _store.setInt(speakingHintsKey, settings.speakingHints ? 1 : 0);
    await _store.setInt(mixSpeakingKey, settings.mixSpeaking ? 1 : 0);
  }

  /// A switch is kept as 1 or 0; a missing value is the default.
  static bool _flag(int? saved, bool fallback) =>
      saved == null ? fallback : saved != 0;

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}
