import 'package:flutter/widgets.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

/// Shorthand for the generated localizations: `context.i18n.appTitle`.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get i18n => AppLocalizations.of(this);
}
