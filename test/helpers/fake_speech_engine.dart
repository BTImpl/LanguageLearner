import 'package:languagelearner/features/play/speaking/speech_engine.dart';

/// A [SpeechEngine] for tests: answers with the readings it was given.
class FakeSpeechEngine implements SpeechEngine {
  FakeSpeechEngine({
    this.access = SpeechAccess.granted,
    this.heard = const [],
    this.statusNow = SpeechStatus.ready,
  });

  /// What [status] answers.
  SpeechStatus statusNow;

  /// What [requestAccess] answers.
  SpeechAccess access;

  /// The readings of the next [listen], the best first.
  List<String> heard;

  /// When set, the next [listen] throws it.
  SpeechException? failure;

  /// The hints of every [listen].
  final hintsGiven = <List<String>>[];
  var stops = 0;
  var accessRequests = 0;

  @override
  Future<SpeechStatus> status() async => statusNow;

  @override
  Future<SpeechAccess> requestAccess() async {
    accessRequests++;
    return access;
  }

  @override
  Future<SpeechHearing> listen({
    required List<String> hints,
    void Function(String text)? onPartial,
    Duration maxDuration = const Duration(seconds: 8),
  }) async {
    hintsGiven.add(hints);
    final error = failure;
    if (error != null) {
      throw error;
    }
    return SpeechHearing(alternatives: heard);
  }

  @override
  Future<void> stop() async => stops++;
}
