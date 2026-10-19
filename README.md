# LanguageLearner

[![CI](https://github.com/BTImpl/LanguageLearner/actions/workflows/ci.yml/badge.svg)](https://github.com/BTImpl/LanguageLearner/actions/workflows/ci.yml)

Mobile app for practising English vocabulary. The teacher enters the words in a
Google Sheet, and each student sees the words from their own tab. Built with
Flutter, currently iOS only; the Android port is tracked on the Trello card
LL-36.

- Package identifier: `eu.btimpl.languagelearner`
- State management: `flutter_riverpod`
- Lints: `flutter_lints` plus a stricter `analysis_options.yaml`

## Running

```
flutter pub get
open -a Simulator
flutter run
```

## Testing and checks

```
flutter analyze
flutter test
tool/format.sh check   # or 'tool/format.sh fix' to format
```

## Project structure

```
lib/
  main.dart            entry point (ProviderScope)
  app/                 app root, router, theme, UI locale
  i18n/                ARB files and generated localizations
  core/                shared widgets and services
    widgets/
    services/
  features/<feature>/  home, flashcards, matching, quiz, typing, mix,
                       stats, settings, auth
test/                  widget and unit tests, mirroring the lib/ structure
ios/                   iOS platform project
```

## Localization

The UI is available in English and Hungarian. All user-facing text lives in
`lib/i18n/*.arb`; widgets never contain hard-coded strings.

The app language follows the device language (English for any language other
than Hungarian or English). The Settings screen will let the user override it
(cards LL-08 and LL-09). Text-to-speech is always English.

To add a string:

1. Add the key to `lib/i18n/app_en.arb` with an `@key` description (and
   placeholders if needed), then add the translation to `lib/i18n/app_hu.arb`.
2. Run `flutter gen-l10n` (`flutter pub get` and `flutter run` do it too).
3. Use it in a widget: `context.i18n.yourKey`.

Commit the generated `lib/i18n/app_localizations*.dart` files. A test fails if
the two ARB files have different keys.

## Google sign-in

Students sign in with the Google account their teacher added to the
spreadsheet (`google_sign_in` 7.x). The app asks only for the basic profile
(name, e-mail); the backend reads the spreadsheet itself. The ID token goes to
the backend as a bearer token and is renewed silently shortly before it
expires (`AuthRepository.idToken()`).

Configuration, none of it secret:

- `ios/Runner/Info.plist`: `GIDClientID` (the iOS OAuth client) and the
  reversed client id as a URL scheme.
- `AppConfig.googleServerClientId`: the web OAuth client, the audience the
  backend checks in the ID token (the backend's `AUTH_GOOGLE_CLIENT_ID`). The
  default is the production client; use another project with
  `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>`.

On start the app tries to sign in silently (5 seconds at most). Without a
signed-in student every route leads to the sign-in screen
(`signInRedirect` in `lib/app/router.dart`).

## Git hook

A pre-commit hook runs the formatting check before every commit, the same
check the CI runs. Enable it once per clone:

```
git config core.hooksPath .githooks
```

If it fails, run `tool/format.sh fix`, stage the changes and commit again.
The hook is skipped (with a warning) when `dart` is not in the PATH, for
example when committing from a GUI; the CI still catches it.
