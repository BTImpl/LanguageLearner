import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/models/word_pair.dart';
import 'package:languagelearner/core/widgets/choice_tile.dart';
import 'package:languagelearner/features/play/matching/match_tile.dart';
import 'package:languagelearner/features/play/matching/matching_game.dart';
import 'package:languagelearner/features/play/play_mode.dart';

/// The key of the live tile of [word] in the column [side], for tests.
Key matchTileKey(WordPair word, MatchSide side) =>
    Key('match-tile-${side.name}-${word.id}');

/// The body of the matching game: the heading and the two columns of tiles.
/// It has no frame (title, counters), so the matching screen and the Mix mode
/// can both use it.
///
/// It shows the page of [game] and must be rebuilt when the game changes.
class MatchingContent extends StatefulWidget {
  const MatchingContent({required this.game, super.key});

  final MatchingGame game;

  @override
  State<MatchingContent> createState() => _MatchingContentState();
}

class _MatchingContentState extends State<MatchingContent> {
  // The tiles of the page in the order they were laid out. A pair that is gone
  // leaves its place empty, so the other tiles do not move.
  var _slotPage = -1;
  var _englishSlots = <WordPair>[];
  var _hungarianSlots = <WordPair>[];

  void _onTap(WordPair word, MatchSide side) {
    final game = widget.game;
    game.tap(word, side);
    switch (game.tile(word, side)?.state) {
      case TileState.matched:
        HapticFeedback.lightImpact().ignore();
      case TileState.wrong:
        HapticFeedback.heavyImpact().ignore();
      case _:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final c = context.colors;
    // An empty page is a page that has just been solved: keep what was laid
    // out until the game moves on.
    if (game.englishTiles.isNotEmpty && _slotPage != game.pageIndex) {
      _slotPage = game.pageIndex;
      _englishSlots = [for (final t in game.englishTiles) t.word];
      _hungarianSlots = [for (final t in game.hungarianTiles) t.word];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PlayMode.matching.hint(context),
          style: TextStyle(
            fontFamily: headingFontFamily,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: c.text,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < _englishSlots.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _slot(_englishSlots[i], MatchSide.english),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _slot(_hungarianSlots[i], MatchSide.hungarian),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _slot(WordPair word, MatchSide side) {
    final game = widget.game;
    final tile = game.tile(word, side);
    final label = switch (side) {
      MatchSide.english => word.english,
      MatchSide.hungarian => word.hungarian,
    };
    if (tile == null) {
      return _GoneTile(label: label);
    }
    final state = switch (tile.state) {
      TileState.idle => ChoiceState.idle,
      TileState.selected => ChoiceState.selected,
      TileState.matched => ChoiceState.correct,
      TileState.wrong => ChoiceState.wrong,
    };
    final canTap =
        tile.state == TileState.idle || tile.state == TileState.selected;
    return AnimatedOpacity(
      // A found pair fades out in the time it stays on the screen.
      opacity: tile.state == TileState.matched ? 0 : 1,
      curve: Curves.easeIn,
      duration: game.matchedDelay,
      child: ChoiceTile(
        key: matchTileKey(word, side),
        label: label,
        state: state,
        onTap: canTap ? () => _onTap(word, side) : null,
      ),
    );
  }
}

/// The empty place of a pair that is gone. It is as high as the tile was, so
/// the tiles around it stay where they are.
class _GoneTile extends StatelessWidget {
  const _GoneTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: bodyFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
