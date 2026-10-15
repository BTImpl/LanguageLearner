import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/play/round/prompt_language_providers.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

void main() {
  test('flipped gives the other direction', () {
    expect(PromptLanguage.english.flipped, PromptLanguage.hungarian);
    expect(PromptLanguage.hungarian.flipped, PromptLanguage.english);
  });

  ProviderContainer containerWith(PromptLanguage fromSettings) {
    final container = ProviderContainer(
      overrides: [
        initialSettingsProvider.overrideWithValue(
          AppSettings(promptLanguage: fromSettings),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the settings decide until a language is chosen', () {
    final container = containerWith(PromptLanguage.hungarian);

    expect(
      container.read(effectivePromptLanguageProvider),
      PromptLanguage.hungarian,
    );

    container
        .read(promptLanguageOverrideProvider.notifier)
        .choose(PromptLanguage.english);
    expect(
      container.read(effectivePromptLanguageProvider),
      PromptLanguage.english,
    );

    container.read(promptLanguageOverrideProvider.notifier).clear();
    expect(
      container.read(effectivePromptLanguageProvider),
      PromptLanguage.hungarian,
    );
  });
}
