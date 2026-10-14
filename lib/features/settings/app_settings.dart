import 'package:flutter/material.dart';
import 'package:languagelearner/core/models/prompt_language.dart';

export 'package:languagelearner/core/models/prompt_language.dart';

/// The color theme the student picked.
enum ThemeChoice {
  dark(ThemeMode.dark),
  light(ThemeMode.light);

  const ThemeChoice(this.themeMode);

  final ThemeMode themeMode;
}

/// The language of the app interface (not of the read-aloud, which is always
/// English, and not of [PromptLanguage]).
enum AppLanguage {
  /// Follows the device language; any language other than Hungarian and
  /// English falls back to English.
  system(null),
  en(Locale('en')),
  hu(Locale('hu'));

  const AppLanguage(this.locale);

  /// `null` means "follow the device language".
  final Locale? locale;
}

/// What the student can set on the settings screen.
@immutable
class AppSettings {
  const AppSettings({
    this.promptLanguage = PromptLanguage.english,
    this.pairsPerPage = defaultPairsPerPage,
    this.themeChoice = ThemeChoice.dark,
    this.appLanguage = AppLanguage.system,
  }) : assert(
         pairsPerPage >= minPairsPerPage && pairsPerPage <= maxPairsPerPage,
         'pairsPerPage must be between $minPairsPerPage and $maxPairsPerPage',
       );

  static const int minPairsPerPage = 3;
  static const int maxPairsPerPage = 8;
  static const int defaultPairsPerPage = 5;

  /// Which language the app asks in. Default: English.
  final PromptLanguage promptLanguage;

  /// How many pairs one page of the matching game shows, between
  /// [minPairsPerPage] and [maxPairsPerPage]. Default: 5.
  final int pairsPerPage;

  /// Dark or light. Default: dark.
  final ThemeChoice themeChoice;

  /// The interface language. Default: follow the device.
  final AppLanguage appLanguage;

  AppSettings copyWith({
    PromptLanguage? promptLanguage,
    int? pairsPerPage,
    ThemeChoice? themeChoice,
    AppLanguage? appLanguage,
  }) {
    return AppSettings(
      promptLanguage: promptLanguage ?? this.promptLanguage,
      pairsPerPage: pairsPerPage ?? this.pairsPerPage,
      themeChoice: themeChoice ?? this.themeChoice,
      appLanguage: appLanguage ?? this.appLanguage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.promptLanguage == promptLanguage &&
      other.pairsPerPage == pairsPerPage &&
      other.themeChoice == themeChoice &&
      other.appLanguage == appLanguage;

  @override
  int get hashCode =>
      Object.hash(promptLanguage, pairsPerPage, themeChoice, appLanguage);

  @override
  String toString() =>
      'AppSettings($promptLanguage, $pairsPerPage pairs, $themeChoice, '
      '$appLanguage)';
}
