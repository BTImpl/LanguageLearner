import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/data/word_providers.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/features/home/widgets/deck_card.dart';
import 'package:languagelearner/features/home/widgets/deck_picker_sheet.dart';
import 'package:languagelearner/features/home/widgets/home_header.dart';
import 'package:languagelearner/features/home/widgets/mode_tiles.dart';
import 'package:languagelearner/features/home/widgets/word_list_message.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The start screen: the selected deck and the practice modes.
///
/// The deck card and the modes take the place of what is not there yet:
/// a spinner while the very first word list is downloaded, a message with a
/// button when it could not be downloaded or the student has no deck.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider);
    final deck = ref.watch(selectedDeckProvider).value;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenMargin,
            12,
            AppSizes.screenMargin,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              const SizedBox(height: 28),
              Text(
                context.i18n.homeHeadline,
                style: TextStyle(
                  fontFamily: headingFontFamily,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: context.colors.text,
                ),
              ),
              const SizedBox(height: 20),
              if (deck != null) ...[
                DeckCard(
                  deck: deck,
                  onTap: () => unawaited(showDeckPicker(context)),
                ),
                const SizedBox(height: 14),
                ModeTiles(wordCount: deck.words.length),
              ] else if (decks.isLoading)
                const _LoadingDeck()
              else if (decks.hasError)
                WordListFailed(error: decks.error!)
              else
                const NoDecksMessage(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The spinner shown instead of the deck card until the first download ends.
class _LoadingDeck extends StatelessWidget {
  const _LoadingDeck();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.i18n.loadingWords,
        ),
      ),
    );
  }
}
