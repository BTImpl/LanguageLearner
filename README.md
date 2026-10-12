# LanguageLearner

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
dart format --set-exit-if-changed .
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
