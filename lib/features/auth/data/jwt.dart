import 'dart:convert';

/// The expiry time (`exp` claim) of a JWT such as a Google ID token, or `null`
/// if the token cannot be read. The signature is not checked: the backend does
/// that, this only tells when to ask for a new token.
DateTime? jwtExpiry(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    return null;
  }
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload);
    if (claims is Map<String, dynamic>) {
      final exp = claims['exp'];
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          exp.toInt() * 1000,
          isUtc: true,
        );
      }
    }
  } on FormatException {
    // Not a JWT: handled like any unreadable token.
  }
  return null;
}
