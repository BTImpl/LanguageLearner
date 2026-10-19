import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/app/shell/app_bottom_nav.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/auth_state.dart';
import 'package:languagelearner/features/auth/sign_in_screen.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

import '../../helpers/fake_auth_repository.dart';

/// Opens the whole app with the real router, so the sign-in redirects work.
Future<void> _openApp(
  WidgetTester tester,
  FakeAuthRepository repository, {
  AuthState initial = const SignedOut(),
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        initialAuthStateProvider.overrideWithValue(initial),
        appLocaleProvider.overrideWithValue(locale),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _signInButton => find.byType(FilledButton);

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  testWidgets('nobody signed in: every route leads to the sign-in screen', (
    tester,
  ) async {
    await _openApp(tester, repository);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.text('LanguageLearner'), findsOneWidget);
    expect(
      find.text('Sign in with the Google account your teacher added.'),
      findsOneWidget,
    );
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('btimpl.eu'), findsOneWidget);
    expect(find.text('Could not sign in. Try again.'), findsNothing);
  });

  testWidgets('is shown in Hungarian', (tester) async {
    await _openApp(tester, repository, locale: const Locale('hu'));

    expect(
      find.text('Lépj be azzal a Google-fiókkal, amelyet a tanárod felvett.'),
      findsOneWidget,
    );
    expect(find.text('Belépés Google-fiókkal'), findsOneWidget);
  });

  testWidgets('stays dark in light mode', (tester) async {
    await _openApp(
      tester,
      repository,
      settings: const AppSettings(themeChoice: ThemeChoice.light),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.dark.background);
  });

  testWidgets('a student who is signed in already starts on the home screen', (
    tester,
  ) async {
    await _openApp(tester, repository, initial: const SignedIn(testAccount));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.text('KA'), findsOneWidget);
  });

  testWidgets('signing in opens the home screen', (tester) async {
    await _openApp(tester, repository);

    await tester.tap(_signInButton);
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.text('KA'), findsOneWidget);
  });

  testWidgets('while signing in the button is off and shows progress', (
    tester,
  ) async {
    final gate = Completer<void>();
    repository.signInGate = gate;
    await _openApp(tester, repository);

    await tester.tap(_signInButton);
    await tester.pump();

    expect(tester.widget<FilledButton>(_signInButton).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  for (final failure in [AuthFailure.cancelled, AuthFailure.failed]) {
    testWidgets('$failure: shows a message and lets the student try again', (
      tester,
    ) async {
      repository.signInError = AuthException(failure);
      await _openApp(tester, repository);

      await tester.tap(_signInButton);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Could not sign in. Try again.'), findsOneWidget);
      expect(tester.widget<FilledButton>(_signInButton).onPressed, isNotNull);

      repository.signInError = null;
      await tester.tap(_signInButton);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }

  testWidgets('an unknown student gets an explanation and another account', (
    tester,
  ) async {
    await _openApp(
      tester,
      repository,
      initial: const SignedOut(studentNotFound: true),
    );

    expect(
      find.text(
        "We can't find a word list for this account. Ask your teacher to add "
        'you, or sign in with another account.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in with another account'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('the unknown-student text is shown in Hungarian', (tester) async {
    await _openApp(
      tester,
      repository,
      initial: const SignedOut(studentNotFound: true),
      locale: const Locale('hu'),
    );

    expect(find.text('Belépés másik fiókkal'), findsOneWidget);
    expect(find.textContaining('nem találunk szólistát'), findsOneWidget);
  });

  testWidgets('fits a small screen', (tester) async {
    repository.signInError = const AuthException(AuthFailure.failed);
    await _openApp(tester, repository, size: const Size(360, 560));

    await tester.tap(_signInButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Could not sign in. Try again.'), findsOneWidget);
  });

  testWidgets('signing out in the settings returns to the sign-in', (
    tester,
  ) async {
    await _openApp(
      tester,
      repository,
      initial: const SignedIn(testAccount),
      size: const Size(800, 1800),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
  });
}
