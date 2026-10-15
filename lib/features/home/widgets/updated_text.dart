import 'package:intl/intl.dart';
import 'package:languagelearner/core/utils/date_utils.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

/// The "updated ..." part of the deck summary line: "updated today at 9:12"
/// for today, "updated yesterday" for the day before, the date for anything
/// older.
///
/// [updatedAt] and [now] are compared in the time zone of [updatedAt], so
/// pass both in local time.
String updatedText(
  AppLocalizations i18n,
  String locale,
  DateTime updatedAt,
  DateTime now,
) {
  if (isSameDay(updatedAt, now)) {
    return i18n.updatedToday(DateFormat.Hm(locale).format(updatedAt));
  }
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (isSameDay(updatedAt, yesterday)) {
    return i18n.updatedYesterday;
  }
  return i18n.updatedOn(DateFormat.yMd(locale).format(updatedAt));
}
