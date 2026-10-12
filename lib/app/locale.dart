import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The language of the app UI.
///
/// `null` means "follow the device language". Card LL-08 binds this to the
/// stored `appLanguage` setting.
final appLocaleProvider = Provider<Locale?>((ref) => null);

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
