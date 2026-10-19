import 'package:languagelearner/features/auth/account.dart';

/// Whether a student is signed in.
sealed class AuthState {
  const AuthState();
}

/// A student is signed in.
final class SignedIn extends AuthState {
  const SignedIn(this.account);

  final Account account;
}

/// Nobody is signed in: the sign-in screen is shown.
final class SignedOut extends AuthState {
  const SignedOut({this.studentNotFound = false});

  /// The backend does not know the signed-in Google account (HTTP 403
  /// `STUDENT_NOT_FOUND`), so the student was signed out; the sign-in screen
  /// explains it.
  final bool studentNotFound;
}
