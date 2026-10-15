import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The totals of the deck: how many of its words go right first time, and
/// how many answers were given.
class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({
    required this.wordCount,
    required this.knownWords,
    required this.totalAnswers,
    required this.firstTryAnswers,
    super.key,
  });

  /// All words of the deck.
  final int wordCount;

  /// Words whose latest answer was right at the first attempt.
  final int knownWords;

  final int totalAnswers;
  final int firstTryAnswers;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final known = knownWords.clamp(0, wordCount);
    return AppCard(
      borderRadius: AppRadii.wideTile,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.statsSummaryHeadline(wordCount, known),
            style: TextStyle(
              fontFamily: headingFontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          const SizedBox(height: 14),
          AppProgressBar(
            value: wordCount == 0 ? 0 : known / wordCount,
            height: 8,
          ),
          const SizedBox(height: 10),
          Text(
            i18n.statsAnswersLine(totalAnswers, firstTryAnswers),
            style: TextStyle(
              fontFamily: bodyFontFamily,
              fontSize: 14,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
