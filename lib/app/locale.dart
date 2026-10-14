import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

/// The language of the app UI, from the stored settings.
///
/// `null` means "follow the device language".
final appLocaleProvider = Provider<Locale?>(
  (ref) => ref.watch(settingsProvider.select((s) => s.appLanguage.locale)),
);

/// Picks the UI language when the app follows the device language.
///
/// Hungarian and English are supported; any other device language falls back
/// to English.
Locale resolveAppLocale(
  Locale? deviceLocale,
  Iterable<Locale> supportedLocales,
) {
  for (final locale in supportedLocales) {
    if (locale.languageCode == deviceLocale?.languageCode) {
      return locale;
    }
  }
  return const Locale('en');
}
