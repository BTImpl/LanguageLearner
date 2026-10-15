import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/models/deck.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/features/home/widgets/deck_picker_sheet.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';
import 'package:languagelearner/features/stats/data/stats_repository.dart';
import 'package:languagelearner/features/stats/widgets/stats_summary_card.dart';
import 'package:languagelearner/features/stats/widgets/word_stat_row.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The Statistics tab: the totals of the selected deck and its words from
/// the hardest to the easiest.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final deck = ref.watch(selectedDeckProvider).value;
    final summary = deck == null
        ? null
        : ref.watch(deckSummaryProvider(deck.id)).value;
    final stats = deck == null
        ? null
        : ref.watch(wordStatsProvider(deck.id)).value;
    final loaded = deck == null || (summary != null && stats != null);
    final hasData = deck != null && summary != null && summary.totalAnswers > 0;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenMargin,
                12,
                AppSizes.screenMargin,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _Header(deck: deck)),
            ),
            if (loaded && !hasData)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.screenMargin,
                  24,
                  AppSizes.screenMargin,
                  24,
                ),
                sliver: SliverToBoxAdapter(child: _EmptyState()),
              )
            else if (hasData && stats != null) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenMargin,
                  20,
                  AppSizes.screenMargin,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: StatsSummaryCard(
                    wordCount: deck.words.length,
                    knownWords: summary.wordsGoingFirstTry,
                    totalAnswers: summary.totalAnswers,
                    firstTryAnswers: summary.firstTryAnswers,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenMargin,
                  24,
                  AppSizes.screenMargin,
                  8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    context.i18n.statsWordsTitle,
                    style: TextStyle(
                      fontFamily: headingFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ),
              ),
              _WordList(rows: _rows(deck, stats)),
            ],
          ],
        ),
      ),
    );
  }

  /// The answered words of [deck] in the order of [stats] (hardest first),
  /// then the words nobody answered yet, in the order of the deck.
  static List<WordStatRow> _rows(Deck deck, List<WordStat> stats) {
    final byId = {for (final word in deck.words) word.id: word};
    final answeredIds = {for (final stat in stats) stat.wordId};
    return [
      for (final stat in stats)
        if (byId[stat.wordId] case final word?)
          WordStatRow(key: ValueKey(word.id), word: word, stat: stat),
      for (final word in deck.words)
        if (!answeredIds.contains(word.id))
          WordStatRow(key: ValueKey(word.id), word: word),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.deck});

  final Deck? deck;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final deck = this.deck;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.i18n.navStats,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: c.text,
            ),
          ),
        ),
        if (deck != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: '${context.i18n.pickDeck}: ${deck.name}',
              child: Material(
                color: c.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.small,
                  side: BorderSide(color: c.line),
                ),
                child: InkWell(
                  customBorder: const RoundedRectangleBorder(
                    borderRadius: AppRadii.small,
                  ),
                  onTap: () => unawaited(showDeckPicker(context)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.touchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              deck.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: bodyFontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.text,
                              ),
                            ),
                          ),
                          Icon(Icons.expand_more, color: c.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WordList extends StatelessWidget {
  const _WordList({required this.rows});

  final List<WordStatRow> rows;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenMargin),
      sliver: SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) => rows[index],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            i18n.statsEmptyText,
            style: TextStyle(
              fontFamily: bodyFontFamily,
              fontSize: 17,
              height: 1.4,
              color: c.text,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: i18n.statsEmptyAction,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
