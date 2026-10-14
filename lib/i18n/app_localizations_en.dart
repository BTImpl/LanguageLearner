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
}
