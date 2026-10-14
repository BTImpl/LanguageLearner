import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the app keeps its small persistent values. Override in tests.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => SharedPreferencesStore(),
);

/// A tiny key-value storage that survives app restarts.
///
/// An interface, so the logic that uses it can be tested in memory; the app
/// uses [SharedPreferencesStore].
abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
}

/// [KeyValueStore] on top of the `shared_preferences` package.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<int?> getInt(String key) => _preferences.getInt(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> setInt(String key, int value) => _preferences.setInt(key, value);
}
