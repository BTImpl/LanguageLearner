import 'package:languagelearner/features/auth/account.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/data/google_sign_in_client.dart';
import 'package:languagelearner/features/auth/data/jwt.dart';

/// [AuthRepository] with Google: keeps the signed-in identity and renews the
/// ID token silently when it is about to expire.
class GoogleAuthRepository implements AuthRepository {
  GoogleAuthRepository(
    this._client, {
    DateTime Function()? now,
    this.renewBefore = const Duration(minutes: 5),
  }) : _now = now ?? DateTime.now;

  final GoogleSignInClient _client;
  final DateTime Function() _now;

  /// A token that expires within this time is renewed before it is used.
  final Duration renewBefore;

  GoogleIdentity? _identity;
  Future<String>? _renewal;

  @override
  Future<Account?> restore() async {
    final identity = await _client.restore();
    _identity = identity;
    return identity == null ? null : _account(identity);
  }

  @override
  Future<Account> signIn() async {
    final identity = await _client.authenticate();
    _identity = identity;
    return _account(identity);
  }

  @override
  Future<String> idToken({bool forceRefresh = false}) async {
    final current = _identity;
    if (current == null) {
      throw const AuthException(AuthFailure.notSignedIn);
    }
    if (!forceRefresh && !_needsRenewal(current.idToken)) {
      return current.idToken;
    }
    // Calls that arrive together share one renewal.
    return _renewal ??= _renew().whenComplete(() => _renewal = null);
  }

  @override
  Future<void> signOut() async {
    _identity = null;
    await _client.signOut();
  }

  Future<String> _renew() async {
    final GoogleIdentity? renewed;
    try {
      renewed = await _client.restore();
    } on AuthException {
      rethrow;
    } on Object catch (error) {
      throw AuthException(AuthFailure.failed, error);
    }
    if (renewed == null) {
      _identity = null;
      throw const AuthException(AuthFailure.notSignedIn);
    }
    _identity = renewed;
    return renewed.idToken;
  }

  bool _needsRenewal(String idToken) {
    final expiry = jwtExpiry(idToken);
    return expiry == null || !expiry.isAfter(_now().add(renewBefore));
  }

  Account _account(GoogleIdentity identity) =>
      Account(name: identity.name, email: identity.email);
}
