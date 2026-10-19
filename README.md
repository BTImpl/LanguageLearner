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

## Backend

The decks come from the backend (`BTImpl/LanguageLearner-backend`) through
`ApiWordRepository`: `GET /api/v1/decks` and `POST /api/v1/decks/refresh`, with
the Google ID token as a bearer token. Timeouts: 10 seconds to connect, 20
seconds for the answer.

- A 401 answer is retried once with a new token; a second one signs the student
  out.
- A 403 answer (`STUDENT_NOT_FOUND`) signs the student out and the sign-in
  screen explains it.
- Other problems are a `WordLoadException` with a `WordLoadFailure` (no network,
  timeout, word list unavailable, server error) for the screens to explain
  (card LL-31). `decksProvider` does not retry on its own.

### Offline word list

`CachedWordRepository` sits on top of `ApiWordRepository` and keeps the last
downloaded decks in the local SQLite database (`cached_deck`, `cached_word`),
so the app starts and every mode works without a network.

- `getDecks()` answers from the saved decks at once. If they are older than 15
  minutes, they are downloaded again in the background and the screens reload
  when that brought something new. Only the very first start (nothing saved)
  waits for the network.
- `refresh()` always asks the backend and replaces the saved decks. A failed
  download never touches them.
- Signing out forgets the saved decks, so the next student does not see them.

The tables are generated code: after changing `lib/core/database/app_database.dart`
run `dart run build_runner build --delete-conflicting-outputs`.

Build-time settings (`--dart-define`):

| Name | Default | Meaning |
| --- | --- | --- |
| `API_BASE_URL` | the Cloud Run service | the backend, e.g. `http://localhost:8080` for a local one |
| `USE_FAKE_DATA` | `false` | `true` uses the built-in sample decks (the sign-in is still needed) |

```
flutter run --dart-define=USE_FAKE_DATA=true
```

### Statistics sync

Every answered word is saved in the local `attempt` table first, so the local
statistics work offline. `AttemptSyncService` uploads the rows that are not
`synced` to `POST /api/v1/attempts` (the endpoint is idempotent by the id the
phone generated, so sending a row twice is harmless):

- batches of at most 200 rows, the oldest first; a row is marked `synced` only
  after its batch was accepted;
- it runs after a round is saved, at app start, when a student signs in and
  when the app returns to the foreground; only one run at a time;
- a network problem, a timeout or a 5xx answer stops the run silently, and the
  next trigger tries again; the student never sees an error;
- a 400 answer marks the rows of that batch `sync_rejected`, logs it and goes
  on, so a bad row cannot block the queue; rejected rows stay in the local
  statistics;
- on sign-out the waiting rows are uploaded first (at most 5 seconds). The rows
  stay on the phone; they are deleted only when a *different* student signs in
  (`claimAttempts`), so an automatic sign-out loses nothing and no row is ever
  uploaded under another account.

## Git hook

A pre-commit hook runs the formatting check before every commit, the same
check the CI runs. Enable it once per clone:

```
git config core.hooksPath .githooks
```

If it fails, run `tool/format.sh fix`, stage the changes and commit again.
The hook is skipped (with a warning) when `dart` is not in the PATH, for
example when committing from a GUI; the CI still catches it.
