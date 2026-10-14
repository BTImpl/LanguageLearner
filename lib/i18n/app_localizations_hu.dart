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
}
