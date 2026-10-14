import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => StoreSettingsRepository(ref.watch(keyValueStoreProvider)),
);

/// The settings loaded at app start, before the first frame, so the app never
/// flashes the defaults. `main` overrides this with the saved settings.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

/// The current settings. Every change is saved.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> setPromptLanguage(PromptLanguage value) =>
      _update(state.copyWith(promptLanguage: value));

  /// Values outside 3..8 are brought into that range.
  Future<void> setPairsPerPage(int value) => _update(
    state.copyWith(
      pairsPerPage: value.clamp(
        AppSettings.minPairsPerPage,
        AppSettings.maxPairsPerPage,
      ),
    ),
  );

  Future<void> setThemeChoice(ThemeChoice value) =>
      _update(state.copyWith(themeChoice: value));

  Future<void> setAppLanguage(AppLanguage value) =>
      _update(state.copyWith(appLanguage: value));

  /// The screen updates at once; the returned future completes when the
  /// change is saved (or fails if saving fails).
  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }
}
