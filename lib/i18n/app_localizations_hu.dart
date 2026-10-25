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

  @override
  String get photoQuizTitle => 'Kvíz fotóból';

  @override
  String get photoQuizHomeSubtitle => 'Fotózz le egy feladatlapot';

  @override
  String get photoQuizNewBadge => 'Új';

  @override
  String get photoQuizCaptureHeadline => 'Fotózd le a feladatlapot';

  @override
  String get photoQuizCaptureSubtitle =>
      'Az app kiolvassa a kérdéseket, te pedig kitöltöd a kvízt.';

  @override
  String get photoQuizTipStraight =>
      'Tartsd egyenesen, jó fényben, a teljes oldallal.';

  @override
  String get photoQuizTipOnePage => 'Egy fotó egy oldal.';

  @override
  String get photoQuizTipPrivacy =>
      'Lehetőleg ne legyen rajta név vagy más személyes adat.';

  @override
  String get photoQuizTakePhoto => 'Fotó készítése';

  @override
  String get photoQuizChooseFromGallery => 'Választás a galériából';

  @override
  String get photoQuizNoCamera =>
      'Ezen az eszközön nincs használható kamera. Válassz képet a galériából.';

  @override
  String get photoQuizUnusablePhoto =>
      'Ezt a képet nem lehet feldolgozni. Próbálj egy másikat.';

  @override
  String get photoQuizProcessingTitle => 'Beolvasom a feladatlapot…';

  @override
  String get photoQuizProcessingHint =>
      'Ez 10–20 másodpercig is eltarthat. Maradj az appban.';

  @override
  String get photoQuizCancel => 'Mégse';

  @override
  String get photoQuizNewPhoto => 'Új fotó';

  @override
  String get photoQuizErrorTitle => 'Nem sikerült a kvíz';

  @override
  String get photoQuizErrorNoQuestions =>
      'Nem találtam kérdéseket a képen. Próbáld újra jobb fényben, a lap egészét mutatva.';

  @override
  String get photoQuizErrorTooLarge => 'A kép túl nagy. Próbálj egy kisebbet.';

  @override
  String get photoQuizErrorUnsupported =>
      'Ezt a képformátumot nem tudom olvasni. Használj JPEG vagy PNG képet.';

  @override
  String get photoQuizErrorDailyLimit =>
      'Mára elfogyott a kvízkeret. Holnap újra próbálhatod.';

  @override
  String get photoQuizErrorUnavailable =>
      'A beolvasás most nem elérhető. Próbáld később. A fotód megmaradt.';

  @override
  String get photoQuizErrorNoNetwork =>
      'Ellenőrizd a hálózatot. A fotód megmaradt, próbáld újra, ha újra van kapcsolat.';

  @override
  String get photoQuizErrorTimeout =>
      'A szerver nem válaszolt időben. A fotód megmaradt, próbáld újra.';

  @override
  String get photoQuizErrorGeneral => 'Valami hiba történt. Próbáld újra.';

  @override
  String get photoQuizReviewHeadline => 'Kvíz áttekintése';

  @override
  String get photoQuizReviewSubtitle =>
      'Töröld, ami hibásan került be, majd indulhat a kitöltés.';

  @override
  String get photoQuizReviewEmpty => 'Nem maradt kérdés. Fotózd le újra.';

  @override
  String get photoQuizDelete => 'Törlés';

  @override
  String get photoQuizUndo => 'Visszavonás';

  @override
  String get photoQuizQuestionDeleted => 'Kérdés törölve';

  @override
  String get photoQuizRetake => 'Újra fotózom';

  @override
  String get photoQuizStart => 'Kezdés';

  @override
  String photoQuizQuestionCount(int count) {
    return '$count kérdés';
  }

  @override
  String get photoQuizSavedTitle => 'Mentett kvízek';

  @override
  String get photoQuizSavedUntitled => 'Kvíz fotóból';

  @override
  String get photoQuizSavedEmptyTitle => 'Még nincs mentett kvíz';

  @override
  String get photoQuizSavedEmptyMessage => 'A beolvasott kvízek itt jelennek meg, és újra kitölthetők.';

  @override
  String get photoQuizSavedDeleted => 'Kvíz törölve';

  @override
  String get photoQuizSavedDuplicate => 'Ezt a kvízt már elmentetted, a meglévőt használom.';

  @override
  String get photoQuizSavedLoadFailed => 'Nem sikerült betölteni a mentett kvízeket.';

  @override
  String photoQuizSavedFillCount(int count) {
    return '$count× kitöltve';
  }

  @override
  String photoQuizSavedDeleteQuiz(String title) {
    return '$title törlése';
  }

  @override
  String photoQuizSkipped(int count) {
    return '$count kérdést nem sikerült kiolvasni';
  }

  @override
  String photoQuizDeleteQuestion(int number) {
    return '$number. kérdés törlése';
  }

  @override
  String photoQuizFillQuestion(int number) {
    return '$number. kérdés';
  }

  @override
  String get photoQuizPrevious => 'Előző';

  @override
  String get photoQuizNext => 'Következő';

  @override
  String get photoQuizToSummary => 'Összegzés';

  @override
  String photoQuizSummaryProgress(int answered, int total) {
    return '$answered / $total megválaszolva';
  }

  @override
  String get photoQuizNoAnswer => 'nincs válasz';

  @override
  String get photoQuizSubmit => 'Beküldés a tanárnak';

  @override
  String photoQuizOpenQuestion(int number) {
    return '$number. kérdés megnyitása';
  }

  @override
  String get photoQuizLeaveTitle => 'Kilépsz a kvízből?';

  @override
  String get photoQuizLeaveMessage => 'A válaszaid nem mentődnek.';

  @override
  String photoEmailStudent(String name, String email) {
    return 'Diák: $name ($email)';
  }

  @override
  String photoEmailDate(String date) {
    return 'Dátum: $date';
  }

  @override
  String get photoQuizNoTeacherEmail =>
      'Előbb add meg a tanárod e-mail-címét a Beállításokban.';

  @override
  String get photoQuizOpenSettings => 'Megnyitás a Beállításokban';

  @override
  String get photoQuizSendNoMailApp =>
      'Nincs beállított levelezőalkalmazás a telefonon. Állíts be egyet, és próbáld újra. A válaszaid megmaradtak.';

  @override
  String get photoQuizSendFailed =>
      'Nem sikerült megnyitni a levelezőt. Próbáld újra. A válaszaid megmaradtak.';

  @override
  String get photoQuizSentTitle => 'Elküldve a levelezőnek';

  @override
  String get photoQuizSentMessage =>
      'Ellenőrizd, hogy a levelezőben el is küldted-e a levelet. Az app nem tudja megerősíteni, hogy elment.';

  @override
  String get photoQuizSentDone => 'Kész';

  @override
  String get photoQuizErrorNoQuestionsTitle => 'Nem találtam kérdést';

  @override
  String get photoQuizErrorImageTitle => 'Ezt a képet nem tudom feldolgozni';

  @override
  String get photoQuizErrorNoNetworkTitle => 'Nincs internetkapcsolat';

  @override
  String get photoQuizErrorTimeoutTitle => 'Túl sokáig tartott';

  @override
  String get photoQuizErrorDailyLimitTitle => 'Mára elfogytak a kvízek';

  @override
  String photoQuizErrorDailyLimitMessage(int limit) {
    return 'Naponta legfeljebb $limit kvízt készíthetsz fotóból. Holnap újra próbálhatod.';
  }

  @override
  String photoQuizErrorDailyLimitResets(String time) {
    return 'Újra használhatod: $time';
  }

  @override
  String photoQuizDailyUsage(int used, int total) {
    return '$used / $total felhasználva ma';
  }

  @override
  String get photoQuizRetry => 'Újrapróbálom';
}
