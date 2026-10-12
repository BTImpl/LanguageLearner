import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _messageKeys(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('English and Hungarian ARB files have the same message keys', () {
    final en = _messageKeys('lib/i18n/app_en.arb');
    final hu = _messageKeys('lib/i18n/app_hu.arb');

    expect(en.difference(hu), isEmpty, reason: 'keys missing from app_hu.arb');
    expect(hu.difference(en), isEmpty, reason: 'keys missing from app_en.arb');
  });
}
