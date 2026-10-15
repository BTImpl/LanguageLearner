import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
  ];

  /// Brand name. Intentionally the same in every language.
  ///
  /// In en, this message translates to:
  /// **'LanguageLearner'**
  String get appTitle;

  /// Number of words, e.g. in a deck.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No words} =1{1 word} other{{count} words}}'**
  String wordCount(int count);

  /// Label of the back button (screen reader and tooltip).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Screen reader label of an answer tile that was right.
  ///
  /// In en, this message translates to:
  /// **'{label}, correct answer'**
  String choiceCorrect(String label);

  /// Screen reader label of an answer tile that was wrong.
  ///
  /// In en, this message translates to:
  /// **'{label}, wrong answer'**
  String choiceWrong(String label);

  /// Label of the Learn tab (home) in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// Label of the Statistics tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStats;

  /// Label of the Settings tab in the bottom navigation.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Name of the flashcards practice mode.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get modeFlashcards;

  /// Name of the matching practice mode.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get modeMatching;

  /// Name of the multiple-choice quiz practice mode.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get modeQuiz;

  /// Name of the typing practice mode (the word must be typed exactly).
  ///
  /// In en, this message translates to:
  /// **'Exact match'**
  String get modeTyping;

  /// Name of the mixed practice mode.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get modeMix;

  /// Title of the screen shown when a practice round is finished.
  ///
  /// In en, this message translates to:
  /// **'Round complete'**
  String get roundEnd;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Button that signs the student out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Title of the setting that picks the language the app asks in.
  ///
  /// In en, this message translates to:
  /// **'Which language should it ask in?'**
  String get promptLanguageTitle;

  /// Option: the app asks in English.
  ///
  /// In en, this message translates to:
  /// **'In English'**
  String get promptLanguageEnglish;

  /// Option: the app asks in Hungarian.
  ///
  /// In en, this message translates to:
  /// **'In Hungarian'**
  String get promptLanguageHungarian;

  /// Explains the asking language: English.
  ///
  /// In en, this message translates to:
  /// **'You see the English word, you need to know the Hungarian.'**
  String get promptLanguageHintEnglish;

  /// Explains the asking language: Hungarian.
  ///
  /// In en, this message translates to:
  /// **'You see the Hungarian word, you need to know the English.'**
  String get promptLanguageHintHungarian;

  /// Title of the setting that picks the language of the app interface.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageTitle;

  /// Explains the app language setting.
  ///
  /// In en, this message translates to:
  /// **'The language of the menus and labels.'**
  String get appLanguageHint;

  /// Option: follow the device language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appLanguageSystem;

  /// Title of the setting for the number of pairs on a page of the matching game.
  ///
  /// In en, this message translates to:
  /// **'Pairs per page'**
  String get pairsPerPageTitle;

  /// Explains the pairs per page setting.
  ///
  /// In en, this message translates to:
  /// **'In matching, between {min} and {max}'**
  String pairsPerPageHint(int min, int max);

  /// Screen reader label of the minus button of the pairs per page setting.
  ///
  /// In en, this message translates to:
  /// **'Fewer pairs'**
  String get pairsFewer;

  /// Screen reader label of the plus button of the pairs per page setting.
  ///
  /// In en, this message translates to:
  /// **'More pairs'**
  String get pairsMore;

  /// Title of the dark/light theme setting.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// Option: dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Option: light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Row that reads the word list again from the teacher's spreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Refresh word list'**
  String get refreshWordsTitle;

  /// Time of the last refresh, when it was today.
  ///
  /// In en, this message translates to:
  /// **'Last updated today at {time}'**
  String lastRefreshedToday(String time);

  /// Time of the last refresh, when it was before today.
  ///
  /// In en, this message translates to:
  /// **'Last updated {dateTime}'**
  String lastRefreshedOn(String dateTime);

  /// Shown when there is no word list yet.
  ///
  /// In en, this message translates to:
  /// **'Not refreshed yet'**
  String get lastRefreshedNever;

  /// Message shown when refreshing the word list failed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the word list.'**
  String get refreshFailed;

  /// Headline of the home screen.
  ///
  /// In en, this message translates to:
  /// **'What shall we practice today?'**
  String get homeHeadline;

  /// Screen reader label of the monogram button that opens the settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// Part of the deck summary line, e.g. "12 words, updated today at 9:12".
  ///
  /// In en, this message translates to:
  /// **'updated today at {time}'**
  String updatedToday(String time);

  /// Part of the deck summary line when the update was before today.
  ///
  /// In en, this message translates to:
  /// **'updated {dateTime}'**
  String updatedOn(String dateTime);

  /// Number of words the student knew on the first try, on the deck card.
  ///
  /// In en, this message translates to:
  /// **'{count} right first time'**
  String firstTimeCorrect(int count);

  /// Short description of the flashcards mode.
  ///
  /// In en, this message translates to:
  /// **'Flip and listen'**
  String get modeFlashcardsHint;

  /// Short description of the matching mode.
  ///
  /// In en, this message translates to:
  /// **'Find the pair'**
  String get modeMatchingHint;

  /// Short description of the quiz mode.
  ///
  /// In en, this message translates to:
  /// **'One word, four answers'**
  String get modeQuizHint;

  /// Short description of the exact-match typing mode.
  ///
  /// In en, this message translates to:
  /// **'Type it exactly'**
  String get modeTypingHint;

  /// Short description of the mix mode.
  ///
  /// In en, this message translates to:
  /// **'Typing, choosing and matching, mixed'**
  String get modeMixHint;

  /// Title of the deck picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Pick a deck'**
  String get pickDeckTitle;

  /// Label of close buttons (screen reader and tooltip).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Screen reader hint of the deck card that opens the deck picker.
  ///
  /// In en, this message translates to:
  /// **'Pick a deck'**
  String get pickDeck;

  /// Title of the word list on the round-end screen.
  ///
  /// In en, this message translates to:
  /// **'Worth another look'**
  String get reviewAgainTitle;

  /// Button that leaves a screen for the home screen.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// Label of the English side of a flashcard.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Label of the Hungarian side of a flashcard.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get languageHungarian;

  /// Hint at the bottom of the English flashcard side.
  ///
  /// In en, this message translates to:
  /// **'Tap for the Hungarian side'**
  String get flipHintHungarian;

  /// Hint at the bottom of the Hungarian flashcard side.
  ///
  /// In en, this message translates to:
  /// **'Tap for the English side'**
  String get flipHintEnglish;

  /// Button that goes to the previous card.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Button that goes to the next card.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Button on the last card that ends the round.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Label of the button that reads the English word aloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// Button on the round-end screen of the flashcards mode.
  ///
  /// In en, this message translates to:
  /// **'Restart Flashcards'**
  String get restartFlashcards;

  /// Headline of the round-end screen of the flashcards mode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You viewed the card} other{You viewed all {count} cards}}'**
  String cardsViewedHeadline(int count);

  /// Caption of the number of cards on the round-end screen.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get statCards;

  /// Caption of the number of read-alouds on the round-end screen.
  ///
  /// In en, this message translates to:
  /// **'read aloud'**
  String get statReadAloud;

  /// Caption of the elapsed minutes on the round-end screen.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get statMinutes;

  /// Counter of the matching screen, e.g. "Page 2 of 3".
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String matchingPageCounter(int page, int pages);

  /// Caption of the number of found pairs in the matching game.
  ///
  /// In en, this message translates to:
  /// **'pairs found'**
  String get statPairsFound;

  /// Caption of the number of wrong attempts.
  ///
  /// In en, this message translates to:
  /// **'wrong attempts'**
  String get statWrongTries;

  /// Caption of the number of words found without a wrong attempt.
  ///
  /// In en, this message translates to:
  /// **'right first time'**
  String get statFirstTry;

  /// Caption of the number of pages in the matching game.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get statPages;

  /// Headline of the round-end screen of the matching game.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The pair is found} other{All {count} pairs found}}'**
  String matchingHeadline(int count);

  /// Button on the round-end screen of the matching game.
  ///
  /// In en, this message translates to:
  /// **'Restart Matching'**
  String get restartMatching;

  /// Label above the English word in the quiz.
  ///
  /// In en, this message translates to:
  /// **'What does it mean in Hungarian?'**
  String get quizQuestionToHungarian;

  /// Label above the Hungarian word in the quiz.
  ///
  /// In en, this message translates to:
  /// **'How do you say it in English?'**
  String get quizQuestionToEnglish;

  /// Shown under the answers after a wrong choice in the quiz.
  ///
  /// In en, this message translates to:
  /// **'Not this one. Try again!'**
  String get quizTryAgain;

  /// Caption of the number of words answered right at the first choice.
  ///
  /// In en, this message translates to:
  /// **'right first time'**
  String get statGuessed;

  /// Caption of the number of words answered wrong at the first choice.
  ///
  /// In en, this message translates to:
  /// **'wrong first time'**
  String get statWrongFirst;

  /// Headline of the round-end screen of the quiz.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{first} of 1 word went right first time} other{{first} of {total} words went right first time}}'**
  String quizHeadline(int total, int first);

  /// Button on the round-end screen of the quiz.
  ///
  /// In en, this message translates to:
  /// **'Restart Quiz'**
  String get restartQuiz;

  /// Shown instead of the quiz when the deck is too small.
  ///
  /// In en, this message translates to:
  /// **'This mode needs at least 4 words in the deck.'**
  String get quizNeedsWords;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
