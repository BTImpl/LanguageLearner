import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';

/// Whether the app is dark or light, from the stored settings.
final appThemeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider.select((s) => s.themeChoice.themeMode)),
);
