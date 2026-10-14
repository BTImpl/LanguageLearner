import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/utils/date_utils.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The selected deck: name, word count, last update and progress.
///
/// The progress is a fixed placeholder until card LL-26 reads the statistics.
/// [onTap] opens the deck picker (card LL-11); without it the card is static.
class DeckCard extends ConsumerWidget {
  const DeckCard({required this.deck, this.onTap, super.key});

  final Deck deck;
  final VoidCallback? onTap;

  String _summary(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final locale = Localizations.localeOf(context).toString();
    final updated = deck.updatedAt.toLocal();
    final now = ref.watch(clockProvider)();
    final updatedText = isSameDay(updated, now)
        ? i18n.updatedToday(DateFormat.Hm(locale).format(updated))
        : i18n.updatedOn(DateFormat.yMd(locale).add_Hm().format(updated));
    return '${i18n.wordCount(deck.words.length)}, $updatedText';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final total = deck.words.length;
    final known = min(8, total);
    final card = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: headingFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _summary(context, ref),
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 14,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: c.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          AppProgressBar(value: total == 0 ? 0 : known / total),
          const SizedBox(height: 8),
          Text(
            context.i18n.firstTimeCorrect(known),
            style: TextStyle(
              fontFamily: bodyFontFamily,
              fontSize: 13,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return card;
    }
    return Semantics(
      button: true,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}
