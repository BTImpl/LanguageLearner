/// The speech engine behind the read-aloud service: a thin interface over the
/// `flutter_tts` plugin, so the logic around it can be tested without a device.
abstract interface class TtsEngine {
  /// One-time setup of the audio session (e.g. play also with the iOS silent
  /// switch on).
  Future<void> prepare();

  /// Whether the device has a voice for [language], e.g. `en-GB`.
  Future<bool> isLanguageAvailable(String language);

  Future<void> setLanguage(String language);

  Future<void> speak(String text);

  Future<void> stop();
}
