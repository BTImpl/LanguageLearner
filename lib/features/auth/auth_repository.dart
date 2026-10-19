import 'package:languagelearner/features/auth/account.dart';

/// Why an authentication call failed.
enum AuthFailure {
  /// The student closed the sign-in sheet.
  cancelled,

  /// Anything else: no network, bad configuration, no ID token.
  failed,

  /// There is no signed-in student (any more).
  notSignedIn,
}

/// Thrown by an [AuthRepository] when it cannot (re)authenticate.
class AuthException implements Exception {
  const AuthException(this.failure, [this.cause]);

  final AuthFailure failure;

  /// The error that caused this one, if any.
  final Object? cause;

  @override
  String toString() =>
      'AuthException($failure${cause == null ? '' : ': $cause'})';
}

/// Signs the student in with Google and hands out the ID token the backend
/// expects as a bearer token.
///
/// The screens only know this interface; the app uses `GoogleAuthRepository`.
abstract interface class AuthRepository {
  /// Signs in again without any screen, if the student signed in earlier.
  /// Returns `null` when there is nothing to restore.
  Future<Account?> restore();

  /// Opens the Google sign-in. Throws [AuthException] when it fails or the
  /// student cancels.
  Future<Account> signIn();

  /// A valid ID token of the signed-in student, renewed silently shortly
  /// before it expires. With [forceRefresh] a new one is asked for even if the
  /// current one has not expired, e.g. after the backend refused it. Throws
  /// [AuthException] when no token can be given.
  Future<String> idToken({bool forceRefresh = false});

  /// Signs the student out of the app and of the Google session.
  Future<void> signOut();
}
