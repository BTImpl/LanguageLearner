import 'package:languagelearner/core/services/tts_service.dart';

/// A [TtsService] for tests: remembers what it was asked to read.
class FakeTtsService implements TtsService {
  final spoken = <String>[];
  var stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}
