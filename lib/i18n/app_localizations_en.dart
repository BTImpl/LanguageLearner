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

  @override
  String get reviewAgainTitle => 'Worth another look';

  @override
  String get backToHome => 'Back to home';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Hungarian';

  @override
  String get flipHintHungarian => 'Tap for the Hungarian side';

  @override
  String get flipHintEnglish => 'Tap for the English side';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get restartFlashcards => 'Restart Flashcards';

  @override
  String cardsViewedHeadline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You viewed all $count cards',
      one: 'You viewed the card',
    );
    return '$_temp0';
  }

  @override
  String get statCards => 'cards';

  @override
  String get statReadAloud => 'read aloud';

  @override
  String get statMinutes => 'minutes';

  @override
  String matchingPageCounter(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get statPairsFound => 'pairs found';

  @override
  String get statWrongTries => 'wrong attempts';

  @override
  String get statFirstTry => 'right first time';

  @override
  String get statPages => 'pages';

  @override
  String matchingHeadline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count pairs found',
      one: 'The pair is found',
    );
    return '$_temp0';
  }

  @override
  String get restartMatching => 'Restart Matching';

  @override
  String get quizQuestionToHungarian => 'What does it mean in Hungarian?';

  @override
  String get quizQuestionToEnglish => 'How do you say it in English?';

  @override
  String get switchQuestionLanguage => 'Switch the question language';

  @override
  String get quizTryAgain => 'Not this one. Try again!';

  @override
  String get statGuessed => 'right first time';

  @override
  String get statWrongFirst => 'wrong first time';

  @override
  String firstTryHeadline(int total, int first) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$first of $total words went right first time',
      one: '$first of 1 word went right first time',
    );
    return '$_temp0';
  }

  @override
  String get restartQuiz => 'Restart Quiz';

  @override
  String get quizNeedsWords => 'This mode needs at least 4 words in the deck.';

  @override
  String get typingWriteHungarian => 'Write it in Hungarian';

  @override
  String get typingWriteEnglish => 'Write it in English';

  @override
  String get typingAnswerLabel => 'Your answer';

  @override
  String get typingHelp => 'Help';

  @override
  String get typingCheck => 'Check';

  @override
  String get typingMismatch => 'Doesn\'t match. Try again!';

  @override
  String typingHelpCountdown(int seconds) {
    return '$seconds s left';
  }

  @override
  String get statCorrectFirst => 'right first time';

  @override
  String get statWithHelp => 'with help';

  @override
  String get restartTyping => 'Restart Exact match';

  @override
  String get restartMix => 'Restart Mix';

  @override
  String statsSummaryHeadline(int total, int known) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$known of $total words go right first time',
      one: '$known of 1 word goes right first time',
    );
    return '$_temp0';
  }

  @override
  String statsAnswersLine(int total, int first) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total answers in total, $first right first time',
      one: '1 answer in total, $first right first time',
    );
    return '$_temp0';
  }

  @override
  String get statsWordsTitle => 'Words, hardest first';

  @override
  String statsWordRatio(int first, int total) {
    return '$first / $total';
  }

  @override
  String get statsNotPracticed => 'not practiced yet';

  @override
  String get statsEmptyText =>
      'You will see here which words go well. Start a round on the Learn tab.';

  @override
  String get statsEmptyAction => 'Start practicing';

  @override
  String get updatedYesterday => 'updated yesterday';

  @override
  String get deckNotPracticed => 'Not practiced yet';
}
