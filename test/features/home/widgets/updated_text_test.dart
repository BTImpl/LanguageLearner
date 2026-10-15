import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:languagelearner/features/home/widgets/updated_text.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

final _now = DateTime(2026, 10, 15, 15, 30);

String _text(String locale, DateTime updatedAt) => updatedText(
  lookupAppLocalizations(Locale(locale)),
  locale,
  updatedAt,
  _now,
);

void main() {
  // The app does this through its localization delegates; a plain unit test
  // has to load the date formats itself.
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('hu');
  });

  group('in English', () {
    test('says the time for an update of today', () {
      expect(
        _text('en', DateTime(2026, 10, 15, 14, 5)),
        'updated today at 14:05',
      );
    });

    test('says yesterday for an update of the day before', () {
      expect(_text('en', DateTime(2026, 10, 14, 23, 59)), 'updated yesterday');
    });

    test('says the date for anything older', () {
      expect(_text('en', DateTime(2026, 10, 13, 9, 12)), 'updated 10/13/2026');
      expect(_text('en', DateTime(2025, 12, 31, 9, 12)), 'updated 12/31/2025');
    });

    test('knows yesterday across a month boundary', () {
      final now = DateTime(2026, 11, 1, 8);

      expect(
        updatedText(
          lookupAppLocalizations(const Locale('en')),
          'en',
          DateTime(2026, 10, 31, 20),
          now,
        ),
        'updated yesterday',
      );
    });
  });

  group('in Hungarian', () {
    test('says the time for an update of today', () {
      expect(
        _text('hu', DateTime(2026, 10, 15, 14, 5)),
        'frissítve ma 14:05-kor',
      );
    });

    test('says yesterday for an update of the day before', () {
      expect(_text('hu', DateTime(2026, 10, 14, 8)), 'frissítve tegnap');
    });

    test('says the date for anything older', () {
      expect(
        _text('hu', DateTime(2026, 10, 13, 9, 12)),
        'frissítve: 2026. 10. 13.',
      );
    });
  });
}
