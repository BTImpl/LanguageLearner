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
    this.typingAttempts = defaultTypingAttempts,
    this.teacherEmail = '',
  }) : assert(
         pairsPerPage >= minPairsPerPage && pairsPerPage <= maxPairsPerPage,
         'pairsPerPage must be between $minPairsPerPage and $maxPairsPerPage',
       ),
       assert(
         typingAttempts >= minTypingAttempts &&
             typingAttempts <= maxTypingAttempts,
         'typingAttempts must be between $minTypingAttempts and '
         '$maxTypingAttempts',
       );

  static const int minPairsPerPage = 3;
  static const int maxPairsPerPage = 8;
  static const int defaultPairsPerPage = 5;

  static const int minTypingAttempts = 1;
  static const int maxTypingAttempts = 10;
  static const int defaultTypingAttempts = 3;

  /// Which language the app asks in. Default: English.
  final PromptLanguage promptLanguage;

  /// How many pairs one page of the matching game shows, between
  /// [minPairsPerPage] and [maxPairsPerPage]. Default: 5.
  final int pairsPerPage;

  /// Dark or light. Default: dark.
  final ThemeChoice themeChoice;

  /// The interface language. Default: follow the device.
  final AppLanguage appLanguage;

  /// How many wrong answers a written question accepts before the game shows
  /// the right one and moves on, between [minTypingAttempts] and
  /// [maxTypingAttempts]. Default: 3. (The game uses it from card LL-42.)
  final int typingAttempts;

  /// The e-mail address the filled-in photo quizzes are sent to; empty when
  /// the student has not set one. A non-empty value is a valid address (see
  /// `isValidEmail`). Default: empty.
  final String teacherEmail;

  AppSettings copyWith({
    PromptLanguage? promptLanguage,
    int? pairsPerPage,
    ThemeChoice? themeChoice,
    AppLanguage? appLanguage,
    int? typingAttempts,
    String? teacherEmail,
  }) {
    return AppSettings(
      promptLanguage: promptLanguage ?? this.promptLanguage,
      pairsPerPage: pairsPerPage ?? this.pairsPerPage,
      themeChoice: themeChoice ?? this.themeChoice,
      appLanguage: appLanguage ?? this.appLanguage,
      typingAttempts: typingAttempts ?? this.typingAttempts,
      teacherEmail: teacherEmail ?? this.teacherEmail,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.promptLanguage == promptLanguage &&
      other.pairsPerPage == pairsPerPage &&
      other.themeChoice == themeChoice &&
      other.appLanguage == appLanguage &&
      other.typingAttempts == typingAttempts &&
      other.teacherEmail == teacherEmail;

  @override
  int get hashCode => Object.hash(
    promptLanguage,
    pairsPerPage,
    themeChoice,
    appLanguage,
    typingAttempts,
    teacherEmail,
  );

  @override
  String toString() =>
      'AppSettings($promptLanguage, $pairsPerPage pairs, $themeChoice, '
      '$appLanguage, $typingAttempts attempts, teacher e-mail: '
      '${teacherEmail.isEmpty ? 'none' : teacherEmail})';
}
