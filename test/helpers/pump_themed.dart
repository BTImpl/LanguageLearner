import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/i18n/app_localizations.dart';

/// Both themes, for tests that must hold in dark and light mode.
const themeModes = [ThemeMode.dark, ThemeMode.light];

/// Pumps [widget] inside a themed, localized app.
///
/// [widget] is the screen body unless [asScreen] is true (for widgets that
/// bring their own `Scaffold`).
Future<void> pumpThemed(
  WidgetTester tester,
  Widget widget, {
  ThemeMode mode = ThemeMode.dark,
  Locale locale = const Locale('en'),
  bool asScreen = false,
  List<Override> overrides = const [],
}) {
  final app = MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: mode,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: asScreen
        ? widget
        : Scaffold(
            body: Padding(padding: const EdgeInsets.all(20), child: widget),
          ),
  );
  return tester.pumpWidget(ProviderScope(overrides: overrides, child: app));
}
