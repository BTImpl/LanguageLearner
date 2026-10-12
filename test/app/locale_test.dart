import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/locale.dart';

void main() {
  const supported = [Locale('en'), Locale('hu')];

  test('follows a supported device language', () {
    expect(resolveAppLocale(const Locale('hu'), supported), const Locale('hu'));
    expect(resolveAppLocale(const Locale('en'), supported), const Locale('en'));
  });

  test('ignores the country part of the device locale', () {
    expect(
      resolveAppLocale(const Locale('hu', 'HU'), supported),
      const Locale('hu'),
    );
    expect(
      resolveAppLocale(const Locale('en', 'GB'), supported),
      const Locale('en'),
    );
  });

  test('falls back to English for other languages', () {
    expect(resolveAppLocale(const Locale('de'), supported), const Locale('en'));
    expect(resolveAppLocale(null, supported), const Locale('en'));
  });
}
