import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/settings/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue(await _loadSettings()),
      ],
      child: const LanguageLearnerApp(),
    ),
  );
}

/// The saved settings; the defaults if they cannot be read, so a storage
/// problem never keeps the app from starting.
Future<AppSettings> _loadSettings() async {
  try {
    return await StoreSettingsRepository(SharedPreferencesStore()).load();
  } on Exception {
    return const AppSettings();
  }
}
