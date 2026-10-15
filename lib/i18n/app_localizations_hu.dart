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
  String get appearanceTitle => 'Megjelenés';

  @override
  String get themeDark => 'Sötét';

  @override
  String get themeLight => 'Világos';

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
  String get refreshFailed => 'Nem sikerült frissíteni a szólistát.';

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
}
