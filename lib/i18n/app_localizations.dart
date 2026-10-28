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

  /// Title of the setting for how many wrong answers a written question accepts before it moves on.
  ///
  /// In en, this message translates to:
  /// **'Wrong attempts when typing'**
  String get typingAttemptsTitle;

  /// Explains the setting for the number of wrong attempts when typing.
  ///
  /// In en, this message translates to:
  /// **'After this many wrong answers it shows the right one and moves on.'**
  String get typingAttemptsHint;

  /// Screen reader label of the minus button of the typing attempts setting.
  ///
  /// In en, this message translates to:
  /// **'Fewer attempts'**
  String get typingAttemptsFewer;

  /// Screen reader label of the plus button of the typing attempts setting.
  ///
  /// In en, this message translates to:
  /// **'More attempts'**
  String get typingAttemptsMore;

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

  /// Title of the setting for the e-mail address the filled-in photo quizzes are sent to.
  ///
  /// In en, this message translates to:
  /// **'Teacher e-mail address'**
  String get teacherEmailTitle;

  /// Explains the teacher e-mail address setting.
  ///
  /// In en, this message translates to:
  /// **'Filled-in quizzes go here.'**
  String get teacherEmailHint;

  /// Label of the text field of the teacher e-mail address setting; shown inside the empty field and read out by screen readers.
  ///
  /// In en, this message translates to:
  /// **'E-mail address'**
  String get teacherEmailLabel;

  /// Error under the teacher e-mail address field when the text is not an e-mail address.
  ///
  /// In en, this message translates to:
  /// **'This does not look like a valid e-mail address.'**
  String get teacherEmailError;

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

  /// Message shown when refreshing the word list failed; the saved word list stays.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh. You still see the earlier word list.'**
  String get refreshFailed;

  /// Accessibility label of the spinner on the home screen while the first word list is downloaded.
  ///
  /// In en, this message translates to:
  /// **'Loading words…'**
  String get loadingWords;

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

  /// Tooltip of the button in the games that swaps the question and the answer language until the player leaves the game.
  ///
  /// In en, this message translates to:
  /// **'Switch the question language'**
  String get switchQuestionLanguage;

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
  String firstTryHeadline(int total, int first);

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

  /// Label above the English word in the exact-match game.
  ///
  /// In en, this message translates to:
  /// **'Write it in Hungarian'**
  String get typingWriteHungarian;

  /// Label above the Hungarian word in the exact-match game.
  ///
  /// In en, this message translates to:
  /// **'Write it in English'**
  String get typingWriteEnglish;

  /// Label of the input field of the exact-match game.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get typingAnswerLabel;

  /// Button that shows the right answer for a few seconds.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get typingHelp;

  /// Button that checks the typed answer.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get typingCheck;

  /// Shown under the input after a wrong answer.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match. Try again!'**
  String get typingMismatch;

  /// Shown under the input after a wrong answer when only one more attempt is allowed.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match. Last try!'**
  String get typingMismatchLast;

  /// Shown under the input when the attempts ran out, while the right answer is shown and the game moves on.
  ///
  /// In en, this message translates to:
  /// **'Out of tries. Here is the answer.'**
  String get typingGaveUp;

  /// Countdown in the help box, e.g. "2 s left".
  ///
  /// In en, this message translates to:
  /// **'{seconds} s left'**
  String typingHelpCountdown(int seconds);

  /// Caption of the number of words typed right at the first attempt, without help.
  ///
  /// In en, this message translates to:
  /// **'right first time'**
  String get statCorrectFirst;

  /// Caption of the number of words solved with help.
  ///
  /// In en, this message translates to:
  /// **'with help'**
  String get statWithHelp;

  /// Button on the round-end screen of the exact-match game.
  ///
  /// In en, this message translates to:
  /// **'Restart Exact match'**
  String get restartTyping;

  /// Button on the round-end screen of the Mix mode.
  ///
  /// In en, this message translates to:
  /// **'Restart Mix'**
  String get restartMix;

  /// Headline of the statistics summary card: how many words of the deck go right first time.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{{known} of 1 word goes right first time} other{{known} of {total} words go right first time}}'**
  String statsSummaryHeadline(int total, int known);

  /// Line under the progress bar of the statistics summary card.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{1 answer in total, {first} right first time} other{{total} answers in total, {first} right first time}}'**
  String statsAnswersLine(int total, int first);

  /// Title of the word list of the statistics screen.
  ///
  /// In en, this message translates to:
  /// **'Words, hardest first'**
  String get statsWordsTitle;

  /// Right-first-time answers out of all answers of a word, e.g. "1 / 5".
  ///
  /// In en, this message translates to:
  /// **'{first} / {total}'**
  String statsWordRatio(int first, int total);

  /// Shown instead of the bar for a word nobody answered yet.
  ///
  /// In en, this message translates to:
  /// **'not practiced yet'**
  String get statsNotPracticed;

  /// Statistics screen before the first finished round.
  ///
  /// In en, this message translates to:
  /// **'You will see here which words go well. Start a round on the Learn tab.'**
  String get statsEmptyText;

  /// Button of the empty statistics screen that opens the home screen.
  ///
  /// In en, this message translates to:
  /// **'Start practicing'**
  String get statsEmptyAction;

  /// Part of the deck summary line when the update was yesterday.
  ///
  /// In en, this message translates to:
  /// **'updated yesterday'**
  String get updatedYesterday;

  /// Shown on the deck card while no word of the deck was answered.
  ///
  /// In en, this message translates to:
  /// **'Not practiced yet'**
  String get deckNotPracticed;

  /// Text under the app name on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the Google account your teacher added.'**
  String get signInPrompt;

  /// Main button of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInButton;

  /// Shown under the sign-in button when the sign-in failed or was cancelled.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Try again.'**
  String get signInFailed;

  /// Replaces the sign-in text when the backend does not know the signed-in account.
  ///
  /// In en, this message translates to:
  /// **'We can\'t find a word list for this account. Ask your teacher to add you, or sign in with another account.'**
  String get signInStudentNotFound;

  /// Label of the sign-in button after the account was not found.
  ///
  /// In en, this message translates to:
  /// **'Sign in with another account'**
  String get signInOtherAccount;

  /// Button that tries the failed word list download again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Button that refreshes the word list from the empty-state message.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// Title shown when the first word list download fails for lack of network.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noConnectionTitle;

  /// Message under the no-connection title.
  ///
  /// In en, this message translates to:
  /// **'The first download of the word list needs internet.'**
  String get noConnectionMessage;

  /// Title shown when the student has no deck at all.
  ///
  /// In en, this message translates to:
  /// **'No word list yet'**
  String get noDecksTitle;

  /// Message under the no-decks title.
  ///
  /// In en, this message translates to:
  /// **'Ask your teacher, then refresh.'**
  String get noDecksMessage;

  /// Title shown when the backend cannot read the spreadsheet (503).
  ///
  /// In en, this message translates to:
  /// **'The word list is not available right now'**
  String get wordsUnavailableTitle;

  /// Message under the unavailable title.
  ///
  /// In en, this message translates to:
  /// **'Please try again a little later.'**
  String get wordsUnavailableMessage;

  /// Title shown for other word list download problems.
  ///
  /// In en, this message translates to:
  /// **'Could not download the word list'**
  String get wordsLoadFailedTitle;

  /// Message under the download-failed title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get wordsLoadFailedMessage;

  /// Caption of the deck card when the deck is empty.
  ///
  /// In en, this message translates to:
  /// **'This deck has no words'**
  String get deckNoWords;

  /// Title of the dialog that asks before leaving a running round.
  ///
  /// In en, this message translates to:
  /// **'Leave the round?'**
  String get leaveRoundTitle;

  /// Message of the leave-round dialog.
  ///
  /// In en, this message translates to:
  /// **'Your result so far will not be saved.'**
  String get leaveRoundMessage;

  /// Button that leaves the round.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveRoundConfirm;

  /// Button that stays in the round.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get leaveRoundCancel;

  /// Shown on a mode tile that is disabled because the deck has too few words.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{At least 1 word needed} other{At least {count} words needed}}'**
  String needsWords(int count);

  /// Title of the message shown when the app may not use the camera.
  ///
  /// In en, this message translates to:
  /// **'No access to the camera'**
  String get photoPermissionCameraTitle;

  /// Title of the message shown when the app may not use the photos.
  ///
  /// In en, this message translates to:
  /// **'No access to your photos'**
  String get photoPermissionPhotosTitle;

  /// Explains how to give the app access to the camera or the photos again.
  ///
  /// In en, this message translates to:
  /// **'Allow it in Settings to make a quiz from a photo.'**
  String get photoPermissionMessage;

  /// Button that opens the system settings of the app.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get photoPermissionOpenSettings;

  /// Title of the quiz made from a photo: on the home screen and in the header of its screens.
  ///
  /// In en, this message translates to:
  /// **'Quiz from a photo'**
  String get photoQuizTitle;

  /// Second line of the home screen entry of the quiz made from a photo.
  ///
  /// In en, this message translates to:
  /// **'Photograph a worksheet'**
  String get photoQuizHomeSubtitle;

  /// Small badge on the home screen entry of the quiz made from a photo.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get photoQuizNewBadge;

  /// Headline of the screen where a photo of a worksheet is taken or chosen.
  ///
  /// In en, this message translates to:
  /// **'Photograph the worksheet'**
  String get photoQuizCaptureHeadline;

  /// Explains what happens with the photo, under the headline of the capture screen.
  ///
  /// In en, this message translates to:
  /// **'The app reads the questions and you fill in the quiz.'**
  String get photoQuizCaptureSubtitle;

  /// Tip on the capture screen about how to hold the worksheet.
  ///
  /// In en, this message translates to:
  /// **'Hold it straight, in good light, with the whole page.'**
  String get photoQuizTipStraight;

  /// Tip on the capture screen: one photo for one page.
  ///
  /// In en, this message translates to:
  /// **'One photo, one page.'**
  String get photoQuizTipOnePage;

  /// Tip on the capture screen about personal data on the worksheet.
  ///
  /// In en, this message translates to:
  /// **'Preferably without a name or other personal data on it.'**
  String get photoQuizTipPrivacy;

  /// Button that opens the camera to photograph a worksheet.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoQuizTakePhoto;

  /// Button that opens the photo gallery to choose the photo of a worksheet.
  ///
  /// In en, this message translates to:
  /// **'Choose from the gallery'**
  String get photoQuizChooseFromGallery;

  /// Shown when the device has no camera that can be used.
  ///
  /// In en, this message translates to:
  /// **'There is no camera to use on this device. Choose a photo from the gallery.'**
  String get photoQuizNoCamera;

  /// Shown when the chosen photo cannot be read or made small enough.
  ///
  /// In en, this message translates to:
  /// **'This photo cannot be read. Try another one.'**
  String get photoQuizUnusablePhoto;

  /// Title of the screen shown while the photo of a worksheet is read.
  ///
  /// In en, this message translates to:
  /// **'Reading the worksheet…'**
  String get photoQuizProcessingTitle;

  /// Text under the title of the processing screen.
  ///
  /// In en, this message translates to:
  /// **'This can take 10-20 seconds. Stay in the app.'**
  String get photoQuizProcessingHint;

  /// Button that gives up reading the photo.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get photoQuizCancel;

  /// Button that goes back to take or choose another photo after a failure.
  ///
  /// In en, this message translates to:
  /// **'New photo'**
  String get photoQuizNewPhoto;

  /// Title shown when no quiz could be made from the photo.
  ///
  /// In en, this message translates to:
  /// **'The quiz could not be made'**
  String get photoQuizErrorTitle;

  /// Shown when no question could be read from the photo.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t find any questions in the photo. Try again in better light, showing the whole page.'**
  String get photoQuizErrorNoQuestions;

  /// Shown when the photo is larger than the server accepts.
  ///
  /// In en, this message translates to:
  /// **'The photo is too large. Try a smaller one.'**
  String get photoQuizErrorTooLarge;

  /// Shown when the photo is neither a JPEG nor a PNG.
  ///
  /// In en, this message translates to:
  /// **'This image format cannot be read. Use a JPEG or PNG photo.'**
  String get photoQuizErrorUnsupported;

  /// Shown when the student has made all the quizzes allowed for today.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used up today\'s quizzes. Try again tomorrow.'**
  String get photoQuizErrorDailyLimit;

  /// Shown when the service that reads the photo is not available.
  ///
  /// In en, this message translates to:
  /// **'Reading photos is not available right now. Try again later. Your photo is kept.'**
  String get photoQuizErrorUnavailable;

  /// Shown when there is no internet connection while reading the photo.
  ///
  /// In en, this message translates to:
  /// **'Check your connection. Your photo is kept; try again once you are back online.'**
  String get photoQuizErrorNoNetwork;

  /// Shown when reading the photo took too long.
  ///
  /// In en, this message translates to:
  /// **'The server did not answer in time. Your photo is kept; try again.'**
  String get photoQuizErrorTimeout;

  /// Shown for any other problem while reading the photo.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get photoQuizErrorGeneral;

  /// Headline of the review screen of a quiz read from a photo.
  ///
  /// In en, this message translates to:
  /// **'Review the quiz'**
  String get photoQuizReviewHeadline;

  /// Text under the headline of the review screen.
  ///
  /// In en, this message translates to:
  /// **'Delete what was read wrongly, then you can start filling it in.'**
  String get photoQuizReviewSubtitle;

  /// Shown on the review screen when every question was deleted.
  ///
  /// In en, this message translates to:
  /// **'No questions left. Take the photo again.'**
  String get photoQuizReviewEmpty;

  /// Button that deletes one question of the quiz.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get photoQuizDelete;

  /// Action of the message shown after a question was deleted; puts the question back.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get photoQuizUndo;

  /// Message shown after a question was deleted.
  ///
  /// In en, this message translates to:
  /// **'Question deleted'**
  String get photoQuizQuestionDeleted;

  /// Button on the review screen that goes back to take the photo again; the quiz is thrown away.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get photoQuizRetake;

  /// Button on the review screen that starts filling in the quiz.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get photoQuizStart;

  /// How many questions the quiz has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String photoQuizQuestionCount(int count);

  /// Note on the review screen: how many questions could not be read and were left out.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question could not be read} other{{count} questions could not be read}}'**
  String photoQuizSkipped(int count);

  /// Spoken label of the delete button of one question, so that the buttons can be told apart.
  ///
  /// In en, this message translates to:
  /// **'Delete question {number}'**
  String photoQuizDeleteQuestion(int number);

  /// Label above the question while the quiz is filled in.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String photoQuizFillQuestion(int number);

  /// Button that goes to the previous question.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get photoQuizPrevious;

  /// Button that goes to the next question.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get photoQuizNext;

  /// Button on the last question that opens the summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get photoQuizToSummary;

  /// Line on top of the summary: how many questions have an answer.
  ///
  /// In en, this message translates to:
  /// **'{answered} / {total} answered'**
  String photoQuizSummaryProgress(int answered, int total);

  /// Shown in the summary for a question without a chosen option.
  ///
  /// In en, this message translates to:
  /// **'no answer'**
  String get photoQuizNoAnswer;

  /// Button on the summary that sends the answers.
  ///
  /// In en, this message translates to:
  /// **'Send to teacher'**
  String get photoQuizSubmit;

  /// Spoken label of a row of the summary, which opens that question.
  ///
  /// In en, this message translates to:
  /// **'Open question {number}'**
  String photoQuizOpenQuestion(int number);

  /// Question of the confirmation when leaving the quiz that is being filled in.
  ///
  /// In en, this message translates to:
  /// **'Leave the quiz?'**
  String get photoQuizLeaveTitle;

  /// Explanation under the question of the leave confirmation.
  ///
  /// In en, this message translates to:
  /// **'Your answers are not saved.'**
  String get photoQuizLeaveMessage;

  /// Line at the top of the e-mail to the teacher: who sends the answers.
  ///
  /// In en, this message translates to:
  /// **'Student: {name} ({email})'**
  String photoEmailStudent(String name, String email);

  /// Line at the top of the e-mail to the teacher: the day of sending.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String photoEmailDate(String date);

  /// Shown on the summary instead of the send button while the teacher's address is not set.
  ///
  /// In en, this message translates to:
  /// **'Add your teacher\'s e-mail address in the settings first.'**
  String get photoQuizNoTeacherEmail;

  /// Button that opens the settings to add the teacher's e-mail address.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get photoQuizOpenSettings;

  /// Error under the send button when the phone has no mail app.
  ///
  /// In en, this message translates to:
  /// **'No mail app is set up on this phone. Set one up and try again. Your answers are kept.'**
  String get photoQuizSendNoMailApp;

  /// Error under the send button when the mail app could not be opened.
  ///
  /// In en, this message translates to:
  /// **'The mail app could not be opened. Try again. Your answers are kept.'**
  String get photoQuizSendFailed;

  /// Title of the closing screen after the e-mail was handed to the mail app.
  ///
  /// In en, this message translates to:
  /// **'Passed to your mail app'**
  String get photoQuizSentTitle;

  /// Text of the closing screen: the app cannot confirm the sending.
  ///
  /// In en, this message translates to:
  /// **'Make sure you send the e-mail in your mail app. This app cannot tell whether it went out.'**
  String get photoQuizSentMessage;

  /// Button of the closing screen that goes back to the home screen.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get photoQuizSentDone;

  /// Title of the error when no question could be read from the photo.
  ///
  /// In en, this message translates to:
  /// **'No questions found'**
  String get photoQuizErrorNoQuestionsTitle;

  /// Title of the error when the photo is too large or of an unsupported type.
  ///
  /// In en, this message translates to:
  /// **'I can\'t process this photo'**
  String get photoQuizErrorImageTitle;

  /// Title of the error when the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get photoQuizErrorNoNetworkTitle;

  /// Title of the error when the server did not answer in time.
  ///
  /// In en, this message translates to:
  /// **'It took too long'**
  String get photoQuizErrorTimeoutTitle;

  /// Title of the error when the daily limit of quizzes is reached.
  ///
  /// In en, this message translates to:
  /// **'No quizzes left for today'**
  String get photoQuizErrorDailyLimitTitle;

  /// Text of the daily limit error when the limit is known.
  ///
  /// In en, this message translates to:
  /// **'You can make up to {limit} quizzes a day from photos. Try again tomorrow.'**
  String photoQuizErrorDailyLimitMessage(int limit);

  /// Line of the daily limit error: when the count starts again, in local time.
  ///
  /// In en, this message translates to:
  /// **'Available again: {time}'**
  String photoQuizErrorDailyLimitResets(String time);

  /// Under the daily limit error: how many of the daily quizzes are used.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} used today'**
  String photoQuizDailyUsage(int used, int total);

  /// Button of the errors that may pass: sends the same photo again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get photoQuizRetry;

  /// Title of the screen with the quizzes kept on the phone, and the label of the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Saved quizzes'**
  String get photoQuizSavedTitle;

  /// Name of a saved quiz whose worksheet had no title.
  ///
  /// In en, this message translates to:
  /// **'Quiz from a photo'**
  String get photoQuizSavedUntitled;

  /// Title of the empty saved quizzes list.
  ///
  /// In en, this message translates to:
  /// **'No saved quizzes yet'**
  String get photoQuizSavedEmptyTitle;

  /// Explanation of the empty saved quizzes list.
  ///
  /// In en, this message translates to:
  /// **'Quizzes you read from a photo appear here, and you can fill them in again.'**
  String get photoQuizSavedEmptyMessage;

  /// Message shown after a saved quiz was deleted.
  ///
  /// In en, this message translates to:
  /// **'Quiz deleted'**
  String get photoQuizSavedDeleted;

  /// Message shown when the quiz that was just read is already among the saved ones.
  ///
  /// In en, this message translates to:
  /// **'You have already saved this quiz, so I am using the saved one.'**
  String get photoQuizSavedDuplicate;

  /// Message shown when the saved quizzes cannot be read.
  ///
  /// In en, this message translates to:
  /// **'The saved quizzes could not be loaded.'**
  String get photoQuizSavedLoadFailed;

  /// How many times a saved quiz was filled in.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Filled once} other{Filled {count} times}}'**
  String photoQuizSavedFillCount(int count);

  /// Spoken label of the delete button of a saved quiz.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}'**
  String photoQuizSavedDeleteQuiz(String title);
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
