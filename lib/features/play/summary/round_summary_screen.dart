import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/core/widgets/icon_square_button.dart';
import 'package:languagelearner/core/widgets/primary_button.dart';
import 'package:languagelearner/core/widgets/stat_tile.dart';
import 'package:languagelearner/features/play/summary/round_summary_data.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The round-end screen shared by all five modes.
class RoundSummaryScreen extends StatelessWidget {
  const RoundSummaryScreen({required this.data, super.key});

  final RoundSummaryData data;

  void _goHome(BuildContext context) => context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    return PopScope(
      // The system back button leaves for the home screen instead of going
      // back into the finished round.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goHome(context);
        }
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenMargin,
              12,
              AppSizes.screenMargin,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${data.modeName}, ${data.deckName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 15,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                    IconSquareButton(
                      icon: Icons.close,
                      semanticLabel: i18n.close,
                      onPressed: () => _goHome(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeadCard(headline: data.headline),
                        const SizedBox(height: 14),
                        _StatRow(stats: data.stats),
                        if (data.reviewWords.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            i18n.reviewAgainTitle,
                            style: TextStyle(
                              fontFamily: headingFontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ReviewList(words: data.reviewWords),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: data.restartLabel,
                  onPressed: () => context.go(data.restartLocation),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: i18n.backToHome,
                  onPressed: () => _goHome(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeadCard extends StatelessWidget {
  const _HeadCard({required this.headline});

  final String headline;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      borderRadius: AppRadii.flip,
      gradient: c.brandGradient,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.i18n.roundEnd,
              style: TextStyle(
                fontFamily: bodyFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.onBrandGradient,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                headline,
                style: TextStyle(
                  fontFamily: headingFontFamily,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: c.onBrandGradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});

  final List<SummaryStat> stats;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: stats[i].value,
                label: stats[i].label,
                tone: stats[i].tone,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.words});

  final List<ReviewWord> words;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (var i = 0; i < words.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      words[i].prompt,
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      words[i].answer,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 15,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
