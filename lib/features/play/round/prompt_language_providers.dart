import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/core/models/prompt_language.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

/// The question language chosen with the switch button of a game. It is only
/// valid until the player leaves the games and returns to the menu; `null`
/// means the default from the settings is in use.
final promptLanguageOverrideProvider =
    NotifierProvider<PromptLanguageOverride, PromptLanguage?>(
      PromptLanguageOverride.new,
    );

class PromptLanguageOverride extends Notifier<PromptLanguage?> {
  @override
  PromptLanguage? build() => null;

  void choose(PromptLanguage language) => state = language;

  void clear() => state = null;
}

/// The question language the games use now: the switch-button choice if there
/// is one, the default from the settings otherwise.
final effectivePromptLanguageProvider = Provider<PromptLanguage>(
  (ref) =>
      ref.watch(promptLanguageOverrideProvider) ??
      ref.watch(settingsProvider.select((s) => s.promptLanguage)),
);

/// Clears the switch-button choice when the router leaves the game routes.
/// Watched once by the app.
final promptLanguageResetProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);
  void check() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (!path.startsWith('/play/') &&
        ref.read(promptLanguageOverrideProvider) != null) {
      ref.read(promptLanguageOverrideProvider.notifier).clear();
    }
  }

  router.routerDelegate.addListener(check);
  ref.onDispose(() => router.routerDelegate.removeListener(check));
});
