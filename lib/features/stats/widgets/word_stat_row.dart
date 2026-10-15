import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/widgets/app_progress_bar.dart';
import 'package:languagelearner/features/stats/data/stats_repository.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// One row of the word list: the word in both languages, and on the right
/// the share of right-first-time answers with the counts.
///
/// A word with no [stat] has no answers yet; the bar is replaced by a note.
class WordStatRow extends StatelessWidget {
  const WordStatRow({required this.word, this.stat, super.key});

  static const double barWidth = 96;

  final WordPair word;
  final WordStat? stat;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i18n = context.i18n;
    final stat = this.stat;
    final ratio = stat == null
        ? null
        : i18n.statsWordRatio(stat.firstTry, stat.total);

    return Semantics(
      container: true,
      label:
          '${word.english}, ${word.hungarian}, '
          '${ratio ?? i18n.statsNotPracticed}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.english,
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
                      word.hungarian,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 14,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (stat == null)
                Flexible(
                  child: Text(
                    i18n.statsNotPracticed,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: bodyFontFamily,
                      fontSize: 13,
                      color: c.textMuted,
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  width: barWidth,
                  child: AppProgressBar(value: stat.firstTry / stat.total),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    ratio!,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: bodyFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
