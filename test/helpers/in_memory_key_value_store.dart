import 'package:languagelearner/core/services/key_value_store.dart';

/// A [KeyValueStore] in memory, for tests. Sharing one instance between two
/// containers stands for restarting the app.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object>? initial])
    : values = {...?initial};

  final Map<String, Object> values;

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<int?> getInt(String key) async => values[key] as int?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setInt(String key, int value) async => values[key] = value;
}
