import 'package:languagelearner/core/services/tts_engine.dart';
import 'package:languagelearner/core/services/tts_service.dart';

/// [TtsService] that always speaks English: British if the device has such a
/// voice, American otherwise.
///
/// A device problem (no voice, engine error) never reaches the caller: the
/// word is just not read aloud. [isAvailable] tells the screens beforehand
/// whether the device has an English voice at all.
class EnglishTtsService implements TtsService {
  EnglishTtsService(this._engine);

  static const preferredLanguage = 'en-GB';
  static const fallbackLanguage = 'en-US';

  final TtsEngine _engine;
  Future<void>? _ready;
  var _latestRequest = 0;
  var _hasEnglishVoice = true;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final request = ++_latestRequest;
    try {
      await _prepare();
      if (!_hasEnglishVoice) {
        return;
      }
      if (request != _latestRequest) {
        // A newer tap came in while the engine was getting ready.
        return;
      }
      await _engine.stop();
      await _engine.speak(trimmed);
    } on Exception {
      // Not read aloud; see the class documentation.
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _prepare();
      return _hasEnglishVoice;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _latestRequest++;
    try {
      await _engine.stop();
    } on Exception {
      // Nothing to stop.
    }
  }

  Future<void> _prepare() {
    return _ready ??= _setUp().onError<Exception>((error, stackTrace) {
      // Try again at the next request.
      _ready = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> _setUp() async {
    await _engine.prepare();
    final british = await _engine.isLanguageAvailable(preferredLanguage);
    _hasEnglishVoice =
        british || await _engine.isLanguageAvailable(fallbackLanguage);
    if (_hasEnglishVoice) {
      await _engine.setLanguage(british ? preferredLanguage : fallbackLanguage);
    }
  }
}
