import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app may listen.
enum SpeechAccess { granted, denied, unavailable }

/// What the recogniser made of one utterance.
class SpeechHearing {
  const SpeechHearing({required this.alternatives, this.onDevice = false});

  /// The readings, the best first. Empty when nothing was recognised.
  final List<String> alternatives;

  /// Whether the device can recognise English without the network. When it
  /// cannot, the audio may be sent to Apple.
  final bool onDevice;
}

/// Recognition failed for a reason other than silence.
class SpeechException implements Exception {
  const SpeechException(this.code);

  /// `unavailable`, `busy` or `failed`.
  final String code;

  @override
  String toString() => 'SpeechException($code)';
}

/// Listens to the student and returns the readings of the speech recogniser.
abstract interface class SpeechEngine {
  /// Asks for the microphone and the speech recognition, if not asked yet.
  Future<SpeechAccess> requestAccess();

  /// Listens until the speaker pauses, [stop] is called or [maxDuration] has
  /// passed. [hints] are the words the recogniser should expect; [onPartial]
  /// gets the text so far.
  Future<SpeechHearing> listen({
    required List<String> hints,
    void Function(String text)? onPartial,
    Duration maxDuration = const Duration(seconds: 8),
  });

  /// Ends the running [listen] early.
  Future<void> stop();
}

/// The iOS recogniser behind the `eu.btimpl.languagelearner/speech` channel
/// (see `SpeechBridge` in `AppDelegate.swift`).
class MethodChannelSpeechEngine implements SpeechEngine {
  MethodChannelSpeechEngine([MethodChannel? channel])
    : _channel =
          channel ?? const MethodChannel('eu.btimpl.languagelearner/speech') {
    _channel.setMethodCallHandler(_fromNative);
  }

  static const String locale = 'en-GB';

  final MethodChannel _channel;
  void Function(String text)? _onPartial;

  Future<Object?> _fromNative(MethodCall call) async {
    if (call.method == 'partial') {
      _onPartial?.call(call.arguments as String? ?? '');
    }
    return null;
  }

  @override
  Future<SpeechAccess> requestAccess() async {
    try {
      final answer = await _channel.invokeMethod<String>('authorize');
      return switch (answer) {
        'granted' => SpeechAccess.granted,
        'denied' => SpeechAccess.denied,
        _ => SpeechAccess.unavailable,
      };
    } on PlatformException {
      return SpeechAccess.unavailable;
    } on MissingPluginException {
      return SpeechAccess.unavailable;
    }
  }

  @override
  Future<SpeechHearing> listen({
    required List<String> hints,
    void Function(String text)? onPartial,
    Duration maxDuration = const Duration(seconds: 8),
  }) async {
    _onPartial = onPartial;
    try {
      final answer = await _channel.invokeMapMethod<String, Object?>('listen', {
        'locale': locale,
        'hints': hints,
        'maxSeconds': maxDuration.inMilliseconds / 1000,
      });
      final raw = answer?['alternatives'];
      return SpeechHearing(
        alternatives: [if (raw is List) ...raw.whereType<String>()],
        onDevice: answer?['onDevice'] == true,
      );
    } on PlatformException catch (e) {
      throw SpeechException(e.code);
    } on MissingPluginException {
      throw const SpeechException('unavailable');
    } finally {
      _onPartial = null;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Nothing to stop.
    } on MissingPluginException {
      // Nothing to stop.
    }
  }
}

/// The speech engine. Override it in tests with a fake.
final speechEngineProvider = Provider<SpeechEngine>(
  (ref) => MethodChannelSpeechEngine(),
);
