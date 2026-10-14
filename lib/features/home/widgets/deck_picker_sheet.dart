import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Opens the deck picker as a modal bottom sheet. Picking a deck selects it
/// and closes the sheet; closing it any other way changes nothing.
Future<void> showDeckPicker(BuildContext context) {
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      side: BorderSide(color: c.line),
    ),
    builder: (_) => const DeckPickerSheet(),
  );
}

/// The content of the deck picker: a handle, a title with a close button and
/// one row per deck, sorted by name.
class DeckPickerSheet extends ConsumerWidget {
  const DeckPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final i18n = context.i18n;
    final decks = [...?ref.watch(decksProvider).value]
      ..sort((a, b) => _sortKey(a.name).compareTo(_sortKey(b.name)));
    final selectedId = ref.watch(selectedDeckProvider).value?.id;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const SizedBox(width: 40, height: 4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  i18n.pickDeckTitle,
                  style: TextStyle(
                    fontFamily: headingFontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
              ),
              IconSquareButton(
                icon: Icons.close,
                semanticLabel: i18n.close,
                backgroundColor: c.bottomNav,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: decks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final deck = decks[index];
                return _DeckRow(
                  deck: deck,
                  selected: deck.id == selectedId,
                  onTap: () {
                    ref.read(selectedDeckIdProvider.notifier).select(deck.id);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Name order that treats accented Hungarian letters like their base letter.
  static String _sortKey(String name) {
    const from = 'áéíóöőúüű';
    const to = 'aeiooouuu';
    final lower = name.toLowerCase();
    return String.fromCharCodes([
      for (final rune in lower.runes)
        if (from.indexOf(String.fromCharCode(rune)) case final i when i >= 0)
          to.codeUnitAt(i)
        else
          rune,
    ]);
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({
    required this.deck,
    required this.selected,
    required this.onTap,
  });

  final Deck deck;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: '${deck.name}, ${context.i18n.wordCount(deck.words.length)}',
      child: Material(
        color: selected ? c.surfaceRaised : c.bottomNav,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.choice,
          side: BorderSide(
            color: selected ? c.highlight : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadii.choice,
          ),
          onTap: onTap,
          child: SizedBox(
            height: 68,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: bodyFontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        Text(
                          context.i18n.wordCount(deck.words.length),
                          style: TextStyle(
                            fontFamily: bodyFontFamily,
                            fontSize: 14,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected) Icon(Icons.check, color: c.highlight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
