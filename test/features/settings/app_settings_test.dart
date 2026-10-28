import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/settings/app_settings.dart';

// Not a const expression, so the assertion runs when the test runs.
AppSettings _withPairs(int pairs) => AppSettings(pairsPerPage: pairs);
AppSettings _withAttempts(int attempts) =>
    AppSettings(typingAttempts: attempts);

void main() {
  test('has the documented defaults', () {
    const settings = AppSettings();

    expect(settings.promptLanguage, PromptLanguage.english);
    expect(settings.pairsPerPage, 5);
    expect(settings.themeChoice, ThemeChoice.dark);
    expect(settings.appLanguage, AppLanguage.system);
    expect(settings.typingAttempts, 3);
    expect(settings.teacherEmail, '');
    expect(settings.speakingHints, isTrue);
    expect(settings.mixSpeaking, isTrue);
  });

  test('copyWith changes only the given setting', () {
    const settings = AppSettings();

    final changed = settings.copyWith(pairsPerPage: 7);

    expect(changed.pairsPerPage, 7);
    expect(changed.promptLanguage, settings.promptLanguage);
    expect(changed.themeChoice, settings.themeChoice);
    expect(changed.appLanguage, settings.appLanguage);
    expect(changed.typingAttempts, settings.typingAttempts);
    expect(changed.teacherEmail, settings.teacherEmail);
    expect(changed.speakingHints, settings.speakingHints);
    expect(changed.mixSpeaking, settings.mixSpeaking);
    expect(settings.copyWith(speakingHints: false).speakingHints, isFalse);
    expect(settings.copyWith(mixSpeaking: false).mixSpeaking, isFalse);
    expect(settings.copyWith(typingAttempts: 5).typingAttempts, 5);
    expect(
      settings.copyWith(teacherEmail: 'tanar@example.com').teacherEmail,
      'tanar@example.com',
    );
  });

  test('settings with the same values are equal', () {
    expect(const AppSettings(), const AppSettings());
    expect(const AppSettings().hashCode, const AppSettings().hashCode);
    expect(const AppSettings(), isNot(const AppSettings(pairsPerPage: 6)));
    expect(const AppSettings(), isNot(const AppSettings(typingAttempts: 4)));
    expect(
      const AppSettings(),
      isNot(const AppSettings(teacherEmail: 'tanar@example.com')),
    );
    expect(
      const AppSettings(teacherEmail: 'tanar@example.com').hashCode,
      const AppSettings(teacherEmail: 'tanar@example.com').hashCode,
    );
  });

  test('refuses a pairsPerPage outside 3..8', () {
    expect(() => _withPairs(2), throwsA(isA<AssertionError>()));
    expect(() => _withPairs(9), throwsA(isA<AssertionError>()));
    expect(const AppSettings(pairsPerPage: 3).pairsPerPage, 3);
    expect(const AppSettings(pairsPerPage: 8).pairsPerPage, 8);
  });

  test('refuses a typingAttempts outside 1..10', () {
    expect(() => _withAttempts(0), throwsA(isA<AssertionError>()));
    expect(() => _withAttempts(11), throwsA(isA<AssertionError>()));
    expect(const AppSettings(typingAttempts: 1).typingAttempts, 1);
    expect(const AppSettings(typingAttempts: 10).typingAttempts, 10);
  });

  test('the app language maps to a locale', () {
    expect(AppLanguage.system.locale, isNull);
    expect(AppLanguage.en.locale, const Locale('en'));
    expect(AppLanguage.hu.locale, const Locale('hu'));
  });

  test('the theme choice maps to a theme mode', () {
    expect(ThemeChoice.dark.themeMode, ThemeMode.dark);
    expect(ThemeChoice.light.themeMode, ThemeMode.light);
  });
}
