import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/features/play/play_mode.dart';
import 'package:languagelearner/features/play/play_requirements.dart';

/// Guards a game route against being opened directly (a deep link, a restored
/// route) without a deck that fits the mode.
///
/// While the decks load it shows a spinner. Once there is a selected deck with
/// enough words ([hasEnoughWords]) it shows [child] for good. With no deck, a
/// failed download or too few words it sends the student to the home screen,
/// which explains the situation.
///
/// The decision is made once: a later change of the decks (a refresh in the
/// background) must not pull a round away from under the student.
class GameGate extends ConsumerStatefulWidget {
  const GameGate({required this.mode, required this.child, super.key});

  final PlayMode mode;
  final Widget child;

  @override
  ConsumerState<GameGate> createState() => _GameGateState();
}

class _GameGateState extends ConsumerState<GameGate> {
  bool? _open;
  var _redirecting = false;

  @override
  Widget build(BuildContext context) {
    if (_open == null) {
      final decks = ref.watch(selectedDeckProvider);
      final deck = decks.value;
      if (deck != null) {
        _open = hasEnoughWords(widget.mode, deck.words.length);
      } else if (!decks.isLoading) {
        _open = false;
      }
    }
    return switch (_open) {
      true => widget.child,
      false => _GoHome(onGo: _goHome),
      null => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }

  void _goHome() {
    if (_redirecting) {
      return;
    }
    _redirecting = true;
    context.go(AppRoutes.home);
  }
}

/// An empty screen that leaves for the home screen as soon as it is shown.
class _GoHome extends StatefulWidget {
  const _GoHome({required this.onGo});

  final VoidCallback onGo;

  @override
  State<_GoHome> createState() => _GoHomeState();
}

class _GoHomeState extends State<_GoHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onGo();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
