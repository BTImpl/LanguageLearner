import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/settings/email_validator.dart';

void main() {
  test('accepts ordinary addresses', () {
    for (final email in [
      'tanar@example.com',
      'kovacs.eva@iskola.example.hu',
      'a+b@sub.domain.example.org',
      'a@b.c',
      '  tanar@example.com  ',
    ]) {
      expect(isValidEmail(email), isTrue, reason: email);
    }
  });

  test('rejects what is not an address', () {
    for (final email in [
      '',
      '   ',
      'tanar',
      'tanar@',
      '@example.com',
      'tanar@example',
      'tanar@.com',
      'tanar@example.',
      'tanar@@example.com',
      'tan ar@example.com',
      'tanar@exa mple.com',
      'tanar@example..com',
    ]) {
      expect(isValidEmail(email), isFalse, reason: email);
    }
  });
}
