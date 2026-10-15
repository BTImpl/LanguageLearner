import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/clock.dart';
import 'package:languagelearner/features/stats/data/attempt_store.dart';
import 'package:languagelearner/features/stats/data/stats_repository.dart';
import 'package:uuid/uuid.dart';

/// Where the attempts are kept. `main` overrides it with the SQLite database;
/// the default keeps them in memory, which is what tests want.
final attemptStoreProvider = Provider<AttemptStore>(
  (ref) => InMemoryAttemptStore(),
);

/// Makes the id of a new attempt. Override to get predictable ids in tests.
final attemptIdGeneratorProvider = Provider<String Function()>(
  (ref) =>
      () => const Uuid().v4(),
);

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepository(
    store: ref.watch(attemptStoreProvider),
    now: ref.watch(clockProvider),
    newId: ref.watch(attemptIdGeneratorProvider),
  ),
);
