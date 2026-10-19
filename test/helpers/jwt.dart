import 'dart:convert';

/// An unsigned JWT with the given expiry, in the shape of a Google ID token.
String fakeJwt({required DateTime expires}) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = expires.millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'none'})}.${part({'exp': exp})}.signature';
}
