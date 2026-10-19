import 'package:google_sign_in/google_sign_in.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';

/// What the app needs from a Google sign-in: who signed in, and the ID token.
class GoogleIdentity {
  const GoogleIdentity({
    required this.name,
    required this.email,
    required this.idToken,
  });

  final String name;
  final String email;
  final String idToken;
}

/// A thin layer over the `google_sign_in` plugin, so the logic of
/// `GoogleAuthRepository` can be tested without the native sign-in.
abstract interface class GoogleSignInClient {
  /// Signs in again without any screen; `null` if that is not possible.
  Future<GoogleIdentity?> restore();

  /// The interactive sign-in. Throws [AuthException].
  Future<GoogleIdentity> authenticate();

  Future<void> signOut();
}

/// [GoogleSignInClient] on top of the `google_sign_in` plugin (7.x).
///
/// Only the basic profile is requested (e-mail, name): the backend reads the
/// spreadsheet itself, so no authorization scopes are needed. The iOS client
/// id and the URL scheme come from `Info.plist`; [serverClientId] is the web
/// client, the audience the backend checks in the ID token.
class PluginGoogleSignInClient implements GoogleSignInClient {
  PluginGoogleSignInClient({
    required this.serverClientId,
    GoogleSignIn? googleSignIn,
  }) : _google = googleSignIn ?? GoogleSignIn.instance;

  final String serverClientId;
  final GoogleSignIn _google;
  Future<void>? _initialized;

  Future<void> _ensureInitialized() async {
    final pending = _initialized ??= _google.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    try {
      await pending;
    } on Object {
      // Try again next time instead of keeping the failure forever.
      _initialized = null;
      rethrow;
    }
  }

  @override
  Future<GoogleIdentity?> restore() async {
    await _ensureInitialized();
    final account = await _google.attemptLightweightAuthentication();
    return account == null ? null : _identity(account);
  }

  @override
  Future<GoogleIdentity> authenticate() async {
    try {
      await _ensureInitialized();
      return _identity(await _google.authenticate());
    } on GoogleSignInException catch (error) {
      throw AuthException(
        error.code == GoogleSignInExceptionCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.failed,
        error,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _google.signOut();
  }

  GoogleIdentity _identity(GoogleSignInAccount account) {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(AuthFailure.failed, 'No ID token received.');
    }
    final name = account.displayName;
    return GoogleIdentity(
      name: name == null || name.trim().isEmpty ? account.email : name,
      email: account.email,
      idToken: idToken,
    );
  }
}
