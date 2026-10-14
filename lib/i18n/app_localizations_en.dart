// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LanguageLearner';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
      zero: 'No words',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Back';

  @override
  String choiceCorrect(String label) {
    return '$label, correct answer';
  }

  @override
  String choiceWrong(String label) {
    return '$label, wrong answer';
  }

  @override
  String get navLearn => 'Learn';

  @override
  String get navStats => 'Statistics';

  @override
  String get navSettings => 'Settings';

  @override
  String get modeFlashcards => 'Flashcards';

  @override
  String get modeMatching => 'Matching';

  @override
  String get modeQuiz => 'Quiz';

  @override
  String get modeTyping => 'Exact match';

  @override
  String get modeMix => 'Mix';

  @override
  String get roundEnd => 'Round complete';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get signOut => 'Sign out';

  @override
  String get promptLanguageTitle => 'Which language should it ask in?';

  @override
  String get promptLanguageEnglish => 'In English';

  @override
  String get promptLanguageHungarian => 'In Hungarian';

  @override
  String get promptLanguageHintEnglish =>
      'You see the English word, you need to know the Hungarian.';

  @override
  String get promptLanguageHintHungarian =>
      'You see the Hungarian word, you need to know the English.';

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get appLanguageHint => 'The language of the menus and labels.';

  @override
  String get appLanguageSystem => 'System';

  @override
  String get pairsPerPageTitle => 'Pairs per page';

  @override
  String pairsPerPageHint(int min, int max) {
    return 'In matching, between $min and $max';
  }

  @override
  String get pairsFewer => 'Fewer pairs';

  @override
  String get pairsMore => 'More pairs';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get refreshWordsTitle => 'Refresh word list';

  @override
  String lastRefreshedToday(String time) {
    return 'Last updated today at $time';
  }

  @override
  String lastRefreshedOn(String dateTime) {
    return 'Last updated $dateTime';
  }

  @override
  String get lastRefreshedNever => 'Not refreshed yet';

  @override
  String get refreshFailed => 'Could not refresh the word list.';

  @override
  String get homeHeadline => 'What shall we practice today?';

  @override
  String get openSettings => 'Open settings';

  @override
  String updatedToday(String time) {
    return 'updated today at $time';
  }

  @override
  String updatedOn(String dateTime) {
    return 'updated $dateTime';
  }

  @override
  String firstTimeCorrect(int count) {
    return '$count right first time';
  }

  @override
  String get modeFlashcardsHint => 'Flip and listen';

  @override
  String get modeMatchingHint => 'Find the pair';

  @override
  String get modeQuizHint => 'One word, four answers';

  @override
  String get modeTypingHint => 'Type it exactly';

  @override
  String get modeMixHint => 'Typing, choosing and matching, mixed';

  @override
  String get pickDeckTitle => 'Pick a deck';

  @override
  String get close => 'Close';

  @override
  String get pickDeck => 'Pick a deck';
}
