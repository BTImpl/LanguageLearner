import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/locale.dart';
import 'package:languagelearner/features/home/home_screen.dart';
import 'package:languagelearner/i18n/app_localizations.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

class LanguageLearnerApp extends ConsumerWidget {
  const LanguageLearnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => context.i18n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: const HomeScreen(),
    );
  }
}
