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
}

/// The read-aloud service. Override it in tests with a fake.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = EnglishTtsService(FlutterTtsEngine());
  ref.onDispose(() => unawaited(service.stop()));
  return service;
});
