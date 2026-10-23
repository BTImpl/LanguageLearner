// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'LanguageLearner';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count szó',
      one: '1 szó',
      zero: 'Nincs szó',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Vissza';

  @override
  String choiceCorrect(String label) {
    return '$label, helyes válasz';
  }

  @override
  String choiceWrong(String label) {
    return '$label, hibás válasz';
  }

  @override
  String get navLearn => 'Tanulás';

  @override
  String get navStats => 'Statisztika';

  @override
  String get navSettings => 'Beállítások';

  @override
  String get modeFlashcards => 'Kártyák';

  @override
  String get modeMatching => 'Párosító';

  @override
  String get modeQuiz => 'Tanuló';

  @override
  String get modeTyping => 'Pontos egyezés';

  @override
  String get modeMix => 'Mix';

  @override
  String get roundEnd => 'Kör vége';

  @override
  String get settingsTitle => 'Beállítások';

  @override
  String get signOut => 'Kijelentkezés';

  @override
  String get promptLanguageTitle => 'Melyik nyelven kérdezzen?';

  @override
  String get promptLanguageEnglish => 'Angolul';

  @override
  String get promptLanguageHungarian => 'Magyarul';

  @override
  String get promptLanguageHintEnglish =>
      'Az angol szót látod, a magyart kell tudnod.';

  @override
  String get promptLanguageHintHungarian =>
      'A magyar szót látod, az angolt kell tudnod.';

  @override
  String get appLanguageTitle => 'Az app nyelve';

  @override
  String get appLanguageHint => 'A menük és feliratok nyelve.';

  @override
  String get appLanguageSystem => 'Rendszer';

  @override
  String get pairsPerPageTitle => 'Párok egy oldalon';

  @override
  String pairsPerPageHint(int min, int max) {
    return 'A párosítóban, $min és $max között';
  }

  @override
  String get pairsFewer => 'Kevesebb pár';

  @override
  String get pairsMore => 'Több pár';

  @override
  String get typingAttemptsTitle => 'Hibás próbálkozások leíráskor';

  @override
  String get typingAttemptsHint =>
      'Ennyi hibás válasz után mutatja meg a helyeset, és lép tovább.';

  @override
  String get typingAttemptsFewer => 'Kevesebb próbálkozás';

  @override
  String get typingAttemptsMore => 'Több próbálkozás';

  @override
  String get appearanceTitle => 'Megjelenés';

  @override
  String get themeDark => 'Sötét';

  @override
  String get themeLight => 'Világos';

  @override
  String get teacherEmailTitle => 'Tanár e-mail-címe';

  @override
  String get teacherEmailHint => 'Ide megy a kitöltött kvíz.';

  @override
  String get teacherEmailLabel => 'E-mail-cím';

  @override
  String get teacherEmailError => 'Ez nem tűnik érvényes e-mail-címnek.';

  @override
  String get refreshWordsTitle => 'Szólista frissítése';

  @override
  String lastRefreshedToday(String time) {
    return 'Utoljára ma $time-kor';
  }

  @override
  String lastRefreshedOn(String dateTime) {
    return 'Utoljára frissítve: $dateTime';
  }

  @override
  String get lastRefreshedNever => 'Még nem frissítve';

  @override
  String get refreshFailed =>
      'Nem sikerült frissíteni. A korábbi szólistát látod.';

  @override
  String get loadingWords => 'Szavak betöltése…';

  @override
  String get homeHeadline => 'Mit gyakorolunk ma?';

  @override
  String get openSettings => 'Beállítások megnyitása';

  @override
  String updatedToday(String time) {
    return 'frissítve ma $time-kor';
  }

  @override
  String updatedOn(String dateTime) {
    return 'frissítve: $dateTime';
  }

  @override
  String firstTimeCorrect(int count) {
    return '$count megy elsőre';
  }

  @override
  String get modeFlashcardsHint => 'Forgatás, felolvasás';

  @override
  String get modeMatchingHint => 'Keresd meg a párját';

  @override
  String get modeQuizHint => 'Egy szó, négy válasz';

  @override
  String get modeTypingHint => 'Írd le betűre pontosan';

  @override
  String get modeMixHint => 'Írás, választás és párosítás vegyesen';

  @override
  String get pickDeckTitle => 'Válassz paklit';

  @override
  String get close => 'Bezárás';

  @override
  String get pickDeck => 'Pakli választása';

  @override
  String get reviewAgainTitle => 'Ezeket érdemes újra átnézni';

  @override
  String get backToHome => 'Vissza a kezdőlapra';

  @override
  String get languageEnglish => 'Angol';

  @override
  String get languageHungarian => 'Magyar';

  @override
  String get flipHintHungarian => 'Koppints a magyar oldalért';

  @override
  String get flipHintEnglish => 'Koppints az angol oldalért';

  @override
  String get previous => 'Előző';

  @override
  String get next => 'Következő';

  @override
  String get finish => 'Befejezés';

  @override
  String get readAloud => 'Felolvasás';

  @override
  String get restartFlashcards => 'Kártyák újrakezdése';

  @override
  String cardsViewedHeadline(int count) {
    return 'Mind a $count kártyát átnézted';
  }

  @override
  String get statCards => 'kártya';

  @override
  String get statReadAloud => 'felolvasás';

  @override
  String get statMinutes => 'perc';

  @override
  String matchingPageCounter(int page, int pages) {
    return '$page / $pages. oldal';
  }

  @override
  String get statPairsFound => 'pár megvan';

  @override
  String get statWrongTries => 'hibás próbálkozás';

  @override
  String get statFirstTry => 'elsőre megvolt';

  @override
  String get statPages => 'oldal';

  @override
  String matchingHeadline(int count) {
    return 'Mind a $count pár megvan';
  }

  @override
  String get restartMatching => 'Párosító újrakezdése';

  @override
  String get quizQuestionToHungarian => 'Mit jelent magyarul?';

  @override
  String get quizQuestionToEnglish => 'Hogy van angolul?';

  @override
  String get switchQuestionLanguage => 'Kérdés nyelvének váltása';

  @override
  String get quizTryAgain => 'Nem ez az. Próbáld újra!';

  @override
  String get statGuessed => 'elsőre eltalált';

  @override
  String get statWrongFirst => 'elsőre hibás';

  @override
  String firstTryHeadline(int total, int first) {
    return '$total szóból $first ment elsőre';
  }

  @override
  String get restartQuiz => 'Tanuló újrakezdése';

  @override
  String get quizNeedsWords => 'Ehhez a módhoz legalább 4 szó kell a pakliban.';

  @override
  String get typingWriteHungarian => 'Írd le magyarul';

  @override
  String get typingWriteEnglish => 'Írd le angolul';

  @override
  String get typingAnswerLabel => 'A válaszod';

  @override
  String get typingHelp => 'Segítség';

  @override
  String get typingCheck => 'Ellenőrzés';

  @override
  String get typingMismatch => 'Nem egyezik. Próbáld újra!';

  @override
  String get typingMismatchLast => 'Nem egyezik. Utolsó próba!';

  @override
  String get typingGaveUp => 'Elfogytak a próbák. Itt a válasz.';

  @override
  String typingHelpCountdown(int seconds) {
    return 'még $seconds mp látszik';
  }

  @override
  String get statCorrectFirst => 'elsőre jó';

  @override
  String get statWithHelp => 'segítséggel';

  @override
  String get restartTyping => 'Pontos egyezés újrakezdése';

  @override
  String get restartMix => 'Mix újrakezdése';

  @override
  String statsSummaryHeadline(int total, int known) {
    return '$total szóból $known megy elsőre';
  }

  @override
  String statsAnswersLine(int total, int first) {
    return '$total válasz összesen, ebből $first elsőre jó';
  }

  @override
  String get statsWordsTitle => 'Szavak, a legnehezebbtől';

  @override
  String statsWordRatio(int first, int total) {
    return '$first / $total';
  }

  @override
  String get statsNotPracticed => 'még nem gyakoroltad';

  @override
  String get statsEmptyText =>
      'Itt látod majd, mely szavak mennek jól. Indíts el egy kört a Tanulás fülön.';

  @override
  String get statsEmptyAction => 'Gyakorlás indítása';

  @override
  String get updatedYesterday => 'frissítve tegnap';

  @override
  String get deckNotPracticed => 'Még nem gyakoroltad';

  @override
  String get signInPrompt =>
      'Lépj be azzal a Google-fiókkal, amelyet a tanárod felvett.';

  @override
  String get signInButton => 'Belépés Google-fiókkal';

  @override
  String get signInFailed => 'Nem sikerült belépni. Próbáld újra.';

  @override
  String get signInStudentNotFound =>
      'Ezzel a fiókkal nem találunk szólistát. Kérd meg a tanárodat, hogy vegyen fel, vagy lépj be másik fiókkal.';

  @override
  String get signInOtherAccount => 'Belépés másik fiókkal';

  @override
  String get retry => 'Újra';

  @override
  String get refreshAction => 'Frissítés';

  @override
  String get noConnectionTitle => 'Nincs internetkapcsolat';

  @override
  String get noConnectionMessage =>
      'A szólista első letöltéséhez netre van szükség.';

  @override
  String get noDecksTitle => 'Még nincs szólistád';

  @override
  String get noDecksMessage => 'Szólj a tanárodnak, aztán frissíts.';

  @override
  String get wordsUnavailableTitle => 'A szólista most nem érhető el';

  @override
  String get wordsUnavailableMessage => 'Próbáld meg kicsit később.';

  @override
  String get wordsLoadFailedTitle => 'Nem sikerült letölteni a szólistát';

  @override
  String get wordsLoadFailedMessage => 'Valami hiba történt. Próbáld újra.';

  @override
  String get deckNoWords => 'Ebben a pakliban nincs szó';

  @override
  String get leaveRoundTitle => 'Kilépsz a körből?';

  @override
  String get leaveRoundMessage => 'Az eddigi eredmény nem mentődik.';

  @override
  String get leaveRoundConfirm => 'Kilépek';

  @override
  String get leaveRoundCancel => 'Folytatom';

  @override
  String needsWords(int count) {
    return 'Legalább $count szó kell';
  }

  @override
  String get photoPermissionCameraTitle => 'Nincs hozzáférés a kamerához';

  @override
  String get photoPermissionPhotosTitle => 'Nincs hozzáférés a fotóidhoz';

  @override
  String get photoPermissionMessage =>
      'Engedélyezd a Beállításokban, hogy fotóból kvízt készíthess.';

  @override
  String get photoPermissionOpenSettings => 'Megnyitás a Beállításokban';
}
