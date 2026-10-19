import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/services/key_value_store.dart';
import 'package:languagelearner/features/auth/auth_providers.dart';
import 'package:languagelearner/features/stats/data/attempt_sync_providers.dart';
import 'package:languagelearner/features/stats/data/stats_providers.dart';

/// Starts the upload of the local answers (card LL-30) when the app starts,
/// when a student signs in and when the app comes back to the foreground.
/// The upload after a round is started by `recordRound`.
class AttemptSyncTrigger extends ConsumerStatefulWidget {
  const AttemptSyncTrigger({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AttemptSyncTrigger> createState() => _AttemptSyncTriggerState();
}

class _AttemptSyncTriggerState extends ConsumerState<AttemptSyncTrigger>
    with WidgetsBindingObserver {
  // The e-mail of the student whose answers were checked and uploaded last.
  String? _claimedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The sign-in found at app start counts as a sign-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_sync());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_sync());
    }
  }

  Future<void> _sync() async {
    final account = ref.read(accountProvider);
    if (account == null) {
      _claimedFor = null;
      return;
    }
    if (_claimedFor != account.email) {
      final claimed = await claimAttempts(
        keys: () => ref.read(keyValueStoreProvider),
        store: ref.read(attemptStoreProvider),
        email: account.email,
      );
      if (!claimed || !mounted) {
        return;
      }
      _claimedFor = account.email;
      // The local statistics may have been emptied by the claim.
      ref.read(statsRevisionProvider.notifier).bump();
    }
    await ref.read(attemptSyncServiceProvider).sync();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountProvider, (previous, next) {
      if (previous?.email != next?.email) {
        unawaited(_sync());
      }
    });
    return widget.child;
  }
}
