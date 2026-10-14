import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// A row that reads the word list again from the teacher's spreadsheet, with
/// the time of the last refresh below the title.
class RefreshWordsCard extends ConsumerStatefulWidget {
  const RefreshWordsCard({super.key});

  @override
  ConsumerState<RefreshWordsCard> createState() => _RefreshWordsCardState();
}

class _RefreshWordsCardState extends ConsumerState<RefreshWordsCard> {
  var _refreshing = false;

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final failedText = context.i18n.refreshFailed;
    setState(() => _refreshing = true);
    try {
      await ref.read(refreshWordsProvider)();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(failedText)));
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  String _lastUpdatedText(BuildContext context, DateTime? updatedAt) {
    final i18n = context.i18n;
    if (updatedAt == null) {
      return i18n.lastRefreshedNever;
    }
    final updated = updatedAt.toLocal();
    final now = ref.watch(clockProvider)();
    final locale = Localizations.localeOf(context).toString();
    final isToday =
        updated.year == now.year &&
        updated.month == now.month &&
        updated.day == now.day;
    return isToday
        ? i18n.lastRefreshedToday(DateFormat.Hm(locale).format(updated))
        : i18n.lastRefreshedOn(DateFormat.yMd(locale).add_Hm().format(updated));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = context.i18n.refreshWordsTitle;
    final subtitle = _lastUpdatedText(context, ref.watch(lastUpdatedProvider));
    return Semantics(
      button: true,
      enabled: !_refreshing,
      label: '$title. $subtitle',
      onTap: _refreshing ? null : () => unawaited(_refresh()),
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          onTap: _refreshing ? null : () => unawaited(_refresh()),
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadii.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 15,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_refreshing)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Icon(Icons.refresh, color: c.textMuted, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
