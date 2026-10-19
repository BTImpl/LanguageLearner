import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/core/data/word_load_exception.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/widgets/state_message.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Shown instead of the deck and the modes when the word list could not be
/// downloaded and the phone has none saved. The button tries again.
class WordListFailed extends ConsumerWidget {
  const WordListFailed({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = context.i18n;
    final failure = switch (error) {
      WordLoadException(:final failure) => failure,
      _ => null,
    };
    final (icon, title, message) = switch (failure) {
      WordLoadFailure.noNetwork || WordLoadFailure.timeout => (
        Icons.wifi_off_outlined,
        i18n.noConnectionTitle,
        i18n.noConnectionMessage,
      ),
      WordLoadFailure.sheetUnavailable => (
        Icons.cloud_off_outlined,
        i18n.wordsUnavailableTitle,
        i18n.wordsUnavailableMessage,
      ),
      _ => (
        Icons.error_outline,
        i18n.wordsLoadFailedTitle,
        i18n.wordsLoadFailedMessage,
      ),
    };
    return StateMessage(
      icon: icon,
      title: title,
      message: message,
      actionLabel: i18n.retry,
      onAction: () => ref.invalidate(decksProvider),
    );
  }
}

/// Shown instead of the deck and the modes when the student has no deck at
/// all. The button reads the word list again from the spreadsheet.
class NoDecksMessage extends ConsumerStatefulWidget {
  const NoDecksMessage({super.key});

  @override
  ConsumerState<NoDecksMessage> createState() => _NoDecksMessageState();
}

class _NoDecksMessageState extends ConsumerState<NoDecksMessage> {
  var _refreshing = false;

  Future<void> _refresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final failedText = context.i18n.refreshFailed;
    setState(() => _refreshing = true);
    try {
      await ref.read(refreshWordsProvider)();
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(failedText)));
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return StateMessage(
      icon: Icons.menu_book_outlined,
      title: i18n.noDecksTitle,
      message: i18n.noDecksMessage,
      actionLabel: i18n.refreshAction,
      actionLoading: _refreshing,
      onAction: () => unawaited(_refresh()),
    );
  }
}
