# LanguageLearner

Mobilalkalmazás angol szókincs gyakorlásához. A szavakat a tanár egy Google
Táblázatban adja meg, a diák a saját füléhez tartozó szavakat látja. Flutter,
jelenleg csak iOS; az Android portolás a Trello LL-36 kártyáján van.

- Csomagazonosító: `eu.btimpl.languagelearner`
- Állapotkezelés: `flutter_riverpod`
- Lint: `flutter_lints` + szigorított `analysis_options.yaml`

## Futtatás

```
flutter pub get
open -a Simulator
flutter run
```

## Tesztelés és ellenőrzés

```
flutter analyze
flutter test
dart format --set-exit-if-changed .
```

## Mappaszerkezet

```
lib/
  main.dart            belépési pont (ProviderScope)
  app/                 az app gyökere, router, téma
  core/                közös widgetek és szolgáltatások
    widgets/
    services/
  features/<funkció>/  home, flashcards, matching, quiz, typing, mix,
                       stats, settings, auth
test/                  widget- és unit tesztek, a lib/ szerkezetét követve
ios/                   iOS platformprojekt
```
