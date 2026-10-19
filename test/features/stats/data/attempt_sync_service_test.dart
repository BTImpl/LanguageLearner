import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/round/word_outcome.dart';
import 'package:languagelearner/features/stats/data/attempt_record.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/attempt_sync_service.dart';
import 'package:languagelearner/features/stats/data/attempt_uploader.dart';

AttemptRecord _record(int n, {bool synced = false}) => AttemptRecord(
  id: 'a${n.toString().padLeft(4, '0')}',
  deckId: 'travel',
  wordId: 'w1',
  mode: PlayMode.quiz,
  outcome: WordOutcome.firstTry,
  answeredAt: DateTime.utc(2026, 10, 1).add(Duration(minutes: n)),
  synced: synced,
);

/// Records the batches and answers from a script.
class _FakeUploader implements AttemptUploader {
  final batches = <List<String>>[];

  /// Failures to throw for the next calls, in order; empty means success.
  final failures = <AttemptUploadFailure>[];

  /// When set, every call waits for it.
  Completer<void>? gate;

  @override
  Future<void> upload(List<AttemptRecord> records) async {
    batches.add([for (final record in records) record.id]);
    await gate?.future;
    if (failures.isNotEmpty) {
      throw AttemptUploadException(failures.removeAt(0));
    }
  }
}

void main() {
  late InMemoryAttemptStore store;
  late _FakeUploader uploader;
  late AttemptSyncService service;

  setUp(() {
    store = InMemoryAttemptStore();
    uploader = _FakeUploader();
    service = AttemptSyncService(store: store, uploader: uploader);
  });

  Future<List<String>> pendingIds() async => [
    for (final record in await store.pending(limit: 1000)) record.id,
  ];

  test(
    'sends the waiting rows, the oldest first, and marks them synced',
    () async {
      await store.insertAll([_record(3), _record(1), _record(2)]);

      await service.sync();

      expect(uploader.batches, [
        ['a0001', 'a0002', 'a0003'],
      ]);
      expect(await pendingIds(), isEmpty);
    },
  );

  test('does not send rows that are already synced', () async {
    await store.insertAll([_record(1, synced: true), _record(2)]);

    await service.sync();

    expect(uploader.batches, [
      ['a0002'],
    ]);
  });

  test('does nothing without waiting rows', () async {
    await service.sync();

    expect(uploader.batches, isEmpty);
  });

  test('keeps the rows and stays silent when the network fails', () async {
    await store.insertAll([_record(1), _record(2)]);
    uploader.failures.add(AttemptUploadFailure.retryLater);

    await service.sync();

    expect(await pendingIds(), ['a0001', 'a0002']);
  });

  test('sends the same rows again at the next sync after a failure', () async {
    await store.insertAll([_record(1), _record(2)]);
    uploader.failures.add(AttemptUploadFailure.retryLater);
    await service.sync();

    await service.sync();

    expect(uploader.batches, [
      ['a0001', 'a0002'],
      ['a0001', 'a0002'],
    ]);
    expect(await pendingIds(), isEmpty);
  });

  test('an interrupted send leaves the earlier batches synced', () async {
    service = AttemptSyncService(
      store: store,
      uploader: _FailOnSecond(),
      batchSize: 2,
    );
    await store.insertAll([for (var i = 1; i <= 5; i++) _record(i)]);

    await service.sync();
    expect(await pendingIds(), ['a0003', 'a0004', 'a0005']);

    await service.sync();
    expect(await pendingIds(), isEmpty);
  });

  test('splits more than 200 rows into batches of at most 200', () async {
    await store.insertAll([for (var i = 1; i <= 450; i++) _record(i)]);

    await service.sync();

    expect(
      [for (final batch in uploader.batches) batch.length],
      [200, 200, 50],
    );
    expect(uploader.batches.first.first, 'a0001');
    expect(uploader.batches[1].first, 'a0201');
    expect(await pendingIds(), isEmpty);
  });

  test('marks a rejected batch and goes on with the next rows', () async {
    service = AttemptSyncService(
      store: store,
      uploader: uploader,
      batchSize: 2,
    );
    await store.insertAll([for (var i = 1; i <= 4; i++) _record(i)]);
    uploader.failures.add(AttemptUploadFailure.rejected);

    await service.sync();

    expect(uploader.batches, [
      ['a0001', 'a0002'],
      ['a0003', 'a0004'],
    ]);
    expect(await pendingIds(), isEmpty);

    // The rejected rows are never sent again.
    await service.sync();
    expect(uploader.batches, hasLength(2));
  });

  test('keeps rejected rows in the local statistics', () async {
    await store.insertAll([_record(1)]);
    uploader.failures.add(AttemptUploadFailure.rejected);

    await service.sync();

    expect(await store.forDeck('travel'), hasLength(1));
  });

  test(
    'a second call during a run joins it instead of starting another',
    () async {
      await store.insertAll([_record(1)]);
      uploader.gate = Completer<void>();

      final first = service.sync();
      final second = service.sync();
      await Future<void>.delayed(Duration.zero);

      expect(service.isRunning, isTrue);
      expect(uploader.batches, hasLength(1));

      uploader.gate!.complete();
      await Future.wait([first, second]);

      expect(uploader.batches, hasLength(1));
      expect(service.isRunning, isFalse);
    },
  );

  test('a run picks up rows saved while it was running', () async {
    await store.insertAll([_record(1)]);
    uploader.gate = Completer<void>();

    final run = service.sync();
    await Future<void>.delayed(Duration.zero);
    await store.insertAll([_record(2)]);
    unawaited(service.sync());
    uploader.gate!.complete();
    await run;

    expect(await pendingIds(), isEmpty);
  });

  test('can run again after a run is over', () async {
    await store.insertAll([_record(1)]);
    await service.sync();
    await store.insertAll([_record(2)]);

    await service.sync();

    expect(uploader.batches, [
      ['a0001'],
      ['a0002'],
    ]);
  });
}

/// Passes the first call, then fails once with a network problem.
class _FailOnSecond implements AttemptUploader {
  var _calls = 0;

  @override
  Future<void> upload(List<AttemptRecord> records) async {
    _calls++;
    if (_calls == 2) {
      throw const AttemptUploadException(AttemptUploadFailure.retryLater);
    }
  }
}
