import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/auth/data/jwt.dart';

import '../../helpers/jwt.dart';

void main() {
  test('reads the expiry of a token', () {
    final expires = DateTime.utc(2026, 10, 19, 12, 30);

    expect(jwtExpiry(fakeJwt(expires: expires)), expires);
  });

  test('gives null for anything that is not a token', () {
    expect(jwtExpiry(''), isNull);
    expect(jwtExpiry('abc'), isNull);
    expect(jwtExpiry('a.b.c'), isNull);
    expect(jwtExpiry('a.!!!.c'), isNull);
  });

  test('gives null when there is no exp claim', () {
    // {"sub":"1"}
    expect(jwtExpiry('e30.eyJzdWIiOiIxIn0.sig'), isNull);
  });
}
