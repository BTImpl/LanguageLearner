import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/app.dart';
import 'package:languagelearner/app/app_config.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/database/app_database.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/auth/auth_repository.dart';
import 'package:languagelearner/features/auth/auth_state.dart';
import 'package:languagelearner/features/auth/data/google_auth_repository.dart';
import 'package:languagelearner/features/auth/data/google_sign_in_client.dart';
import 'package:languagelearner/features/settings/app_settings.dart';
import 'package:languagelearner/features/settings/settings_providers.dart';
import 'package:languagelearner/features/settings/settings_repository.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Opened lazily on the first query, and kept for the life of the app.
  final database = AppDatabase.persistent();
  final authRepository = GoogleAuthRepository(
    PluginGoogleSignInClient(serverClientId: AppConfig.googleServerClientId),
  );
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        initialAuthStateProvider.overrideWithValue(
          await _restoreSignIn(authRepository),
        ),
        initialSettingsProvider.overrideWithValue(await _loadSettings()),
        initialSelectedDeckIdProvider.overrideWithValue(
          await _loadSelectedDeckId(),
        ),
        attemptStoreProvider.overrideWithValue(DriftAttemptStore(database)),
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

/// The deck id picked in an earlier run, `null` if none or unreadable.
Future<String?> _loadSelectedDeckId() async {
  try {
    return await SharedPreferencesStore().getString(selectedDeckIdKey);
  } on Exception {
    return null;
  }
}

/// How long the silent sign-in may take before the sign-in screen is shown.
const _restoreTimeout = Duration(seconds: 5);

/// Signs in silently if the student signed in earlier; signed out if that is
/// not possible, so a Google problem never keeps the app from starting.
Future<AuthState> _restoreSignIn(AuthRepository repository) async {
  try {
    final account = await repository.restore().timeout(_restoreTimeout);
    return account == null ? const SignedOut() : SignedIn(account);
  } on Exception {
    return const SignedOut();
  }
}
