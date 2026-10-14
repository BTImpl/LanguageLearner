import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/auth/account.dart';

void main() {
  String monogram(String name) =>
      Account(name: name, email: 'a@example.com').monogram;

  test('the monogram is the first letters of the first two words', () {
    expect(monogram('Kiss Anna'), 'KA');
    expect(monogram('Nagy Péter István'), 'NP');
  });

  test('a single word gives one letter', () {
    expect(monogram('Anna'), 'A');
  });

  test('the monogram is upper case and handles accented letters', () {
    expect(monogram('árpád énekes'), 'ÁÉ');
  });

  test(
    'extra spaces do not matter and an empty name gives a question mark',
    () {
      expect(monogram('  Kiss   Anna '), 'KA');
      expect(monogram(''), '?');
      expect(monogram('   '), '?');
    },
  );
}
