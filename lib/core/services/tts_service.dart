import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/english_tts_service.dart';
import 'package:languagelearner/core/services/flutter_tts_engine.dart';

/// Reads English words and phrases aloud.
///
/// It only ever gets English text: the caller must not offer the read-aloud
/// button next to Hungarian text. The language of the voice is always
/// English, whatever the language of the app or the direction of asking.
abstract interface class TtsService {
  /// Reads [text] aloud. A running read-aloud is stopped first, so quick
  /// repeated taps never pile up.
  Future<void> speak(String text);

  /// Stops the running read-aloud, if any.
  Future<void> stop();

  /// Whether the device can read English aloud at all. When it cannot, the
  /// screens hide the read-aloud button.
  Future<bool> isAvailable();
}

/// The read-aloud service. Override it in tests with a fake.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = EnglishTtsService(FlutterTtsEngine());
  ref.onDispose(() => unawaited(service.stop()));
  return service;
});

/// Whether the read-aloud button is worth showing. It is `null` until the
/// device is asked: a screen hides the button only on a definite `false`.
final readAloudAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(ttsServiceProvider).isAvailable(),
);

/// Whether a screen should offer the read-aloud button.
extension ReadAloudAvailability on WidgetRef {
  bool get canReadAloud => watch(readAloudAvailableProvider).value != false;
}
