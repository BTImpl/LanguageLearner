import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A failure the adapter throws instead of answering.
class FakeNetworkFailure {
  const FakeNetworkFailure(this.type, [this.error]);

  final DioExceptionType type;
  final Object? error;
}

/// A Dio adapter for tests: answers from a queue and records the requests.
class FakeHttpAdapter implements HttpClientAdapter {
  final _answers = <Object>[];

  /// Every request received, in order.
  final requests = <RequestOptions>[];

  /// The next answer: JSON with [status].
  void answer(Object? json, {int status = 200}) {
    _answers.add(
      ResponseBody.fromString(
        jsonEncode(json),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  /// The next call fails like a network problem.
  void fail(DioExceptionType type, [Object? error]) =>
      _answers.add(FakeNetworkFailure(type, error));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final next = _answers.removeAt(0);
    if (next is FakeNetworkFailure) {
      throw DioException(
        requestOptions: options,
        type: next.type,
        error: next.error,
      );
    }
    return next as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}
