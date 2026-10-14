# Design

Single source of truth for the visual design. UI cards take their colors,
fonts and shapes from here; the theme code (card LL-04) mirrors this file.

Interactive design: the "LanguageLearner – UI terv" canvas (Claude artifact,
<https://claude.ai/artifact/4811tSc8TMvkxbyMVFLHS7>). Static exports of every
screen are in [`screens/`](screens/).

## Colors, dark mode (default)

| Token | Value | Used for |
| --- | --- | --- |
| background | `#0A1226` | screen background |
| surface | `#141E3A` | cards, sheets |
| surface raised | `#1C2850` | highlighted surfaces, selected rows |
| line | `#26335C` | borders, dividers |
| bottom nav background | `#0E1730` | bottom navigation bar |
| text | `#EEF2FF` | primary text |
| text muted | `#A3AED0` | secondary text |
| primary | `#4FC3F7` | buttons, active menu item, progress indicator |
| on primary | `#0A1226` | text on the primary color |
| indigo | `#5B6CFF` | accent |
| indigo light | `#8C99FF` | icons, selection |
| brand gradient | 165°, `#6C7BFF` → `#4FC3F7` | English side of the flashcard and the round-end header card only |
| on brand gradient | `#0A1226` | text on the gradient |
| success background | `#0F3A2C` | correct answer |
| success border | `#4ADE9B` | correct answer |
| success text | `#C8F7DF` | correct answer |
| success number | `#7FE8B7` | counters |
| error background | `#4A1620` | wrong answer |
| error border | `#FF6B7A` | wrong answer |
| error text | `#FFD5D9` | wrong answer |
| error number | `#FF9AA4` | counters |

## Colors, light mode

| Token | Value |
| --- | --- |
| background | `#F2F4FB` |
| surface | `#FFFFFF` |
| line | `#D9DFF0` |
| text | `#0A1226` |
| text muted | `#56607F` |
| highlight | `#4353E0` |
| primary tile | `#4FC3F7` |

The remaining light-mode tokens were not in the design; they are derived in
`lib/app/theme/app_colors.dart` (card LL-04) and recorded here. `primary`,
`on primary`, `indigo`, the brand gradient and `on brand gradient` are the same
as in dark mode.

| Token | Value | Derived from |
| --- | --- | --- |
| surface raised | `#E6EAFA` | slightly darker than the page background |
| bottom nav background | `#FFFFFF` | same as surface |
| highlight (icons, selection) | `#4353E0` | the design's light-mode highlight |
| success background | `#DDF6E9` | pale tint of the dark-mode green |
| success border | `#1FA971` | dark-mode green, darkened for contrast |
| success text | `#0B4A33` | dark green on the pale background |
| success number | `#12794F` | |
| error background | `#FDE3E6` | pale tint of the dark-mode red |
| error border | `#E5484D` | dark-mode red, darkened for contrast |
| error text | `#6B1520` | dark red on the pale background |
| error number | `#C4293A` | |

In the dark theme `highlight` is `indigo light` (`#8C99FF`).

## Typography

- Headings and large words: **Bricolage Grotesque**, weight 700.
- Everything else: **Figtree**, weights 400, 500, 600, 700.

Both fonts are bundled with the app (`assets/fonts`), not downloaded at
runtime, so the app works offline (card LL-04).

## Shapes and spacing

- Corner radius of buttons: 18. Answer and pair tiles: 16. Small buttons:
  12–14.
- Cards have an asymmetric corner with a larger bottom-right radius. Radii are
  written in CSS order: top-left / top-right / bottom-right / bottom-left.
  - tiles: 18 / 18 / 36 / 18
  - highlighted cards: 28 / 28 / 64 / 28
  - the flip card: 28 / 28 / 84 / 28
- Side margin: 20.
- Touch targets are at least 44 high.

## Logo

`assets/branding/icon-512.png` (512 × 512). For the iOS app icon a 1024 × 1024
source without transparency or rounded corners is needed (card LL-32).

## Screens

Exported from the canvas, one PNG per screen, in `screens/`. File names are
English and follow the feature folders in `lib/features/`; the table maps them
to the Hungarian canvas titles used on the Trello cards.

| File | Canvas title (Trello) | Used by |
| --- | --- | --- |
| `01-home.png` | Kezdőlap | LL-04, LL-06, LL-10, LL-26, LL-27, LL-29, LL-32 |
| `02-home-light.png` | Kezdőlap, világos mód | LL-04, LL-10 |
| `03-flashcards.png` | Kártyák | LL-15 |
| `04-round-end-flashcards.png` | Kör vége, Kártyák | LL-15 |
| `05-matching.png` | Párosító | LL-05, LL-17 |
| `06-round-end-matching.png` | Kör vége, Párosító | LL-17 |
| `07-quiz.png` | Tanuló | LL-05, LL-19 |
| `08-round-end-quiz.png` | Kör vége, Tanuló | LL-19 |
| `09-typing.png` | Pontos egyezés | LL-05, LL-21 |
| `10-round-end-typing.png` | Kör vége, Pontos egyezés | LL-21 |
| `11-mix.png` | Mix | LL-23 |
| `12-round-end-mix.png` | Kör vége, Mix | LL-14, LL-23 |
| `13-stats.png` | Statisztika | LL-06, LL-25 |
| `14-settings.png` | Beállítások | LL-06, LL-09, LL-27, LL-29 |
| `15-sign-in.png` | Belépés | LL-27 |
| `16-deck-picker.png` | Pakliválasztó | LL-11, LL-25 |

The settings screen design (`14-settings.png`) predates the "App language"
card. It is built in card LL-09 in the style of the "Appearance" card: a title,
a hint line ("The language of the menus and labels.") and a three-way toggle
(System / English / Magyar). The language names are not translated. The screen
texts in the designs are Hungarian; the English translations are in the
localization files (card LL-37).
