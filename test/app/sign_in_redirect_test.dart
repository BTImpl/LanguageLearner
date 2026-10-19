import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/features/auth/auth_state.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  test('signed out: everything but the sign-in leads to the sign-in', () {
    const out = SignedOut();

    expect(signInRedirect(out, AppRoutes.home), AppRoutes.signIn);
    expect(signInRedirect(out, AppRoutes.settings), AppRoutes.signIn);
    expect(signInRedirect(out, '/play/mix'), AppRoutes.signIn);
    expect(signInRedirect(out, AppRoutes.signIn), isNull);
  });

  test('signed in: the sign-in leads home, the rest stays', () {
    const signedIn = SignedIn(testAccount);

    expect(signInRedirect(signedIn, AppRoutes.signIn), AppRoutes.home);
    expect(signInRedirect(signedIn, AppRoutes.home), isNull);
    expect(signInRedirect(signedIn, AppRoutes.stats), isNull);
    expect(signInRedirect(signedIn, '/play/quiz'), isNull);
  });
}
