import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/features/play/play_mode.dart';

const _modeIcons = <PlayMode, IconData>{
  PlayMode.flashcards: Icons.filter_none,
  PlayMode.matching: Icons.account_tree_outlined,
  PlayMode.quiz: Icons.grid_view_outlined,
  PlayMode.typing: Icons.edit_outlined,
  PlayMode.mix: Icons.shuffle,
};

/// The wide Mix tile on top of the 2 x 2 grid of the other modes.
class ModeTiles extends StatelessWidget {
  const ModeTiles({super.key});

  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MixTile(),
        const SizedBox(height: _gap),
        _row(PlayMode.flashcards, PlayMode.matching),
        const SizedBox(height: _gap),
        _row(PlayMode.quiz, PlayMode.typing),
      ],
    );
  }

  Widget _row(PlayMode left, PlayMode right) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _ModeTile(mode: left)),
        const SizedBox(width: _gap),
        Expanded(child: _ModeTile(mode: right)),
      ],
    ),
  );
}

class _MixTile extends StatelessWidget {
  const _MixTile();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const mode = PlayMode.mix;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${mode.title(context)}. ${mode.hint(context)}',
      child: Material(
        color: c.primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.wideTile),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadii.wideTile,
          ),
          onTap: () => context.go(AppRoutes.play(mode)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.title(context),
                        style: TextStyle(
                          fontFamily: headingFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: c.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.hint(context),
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 14,
                          color: c.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(_modeIcons[mode], size: 32, color: c.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode});

  final PlayMode mode;

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadii.tile,
    side: BorderSide(color: Colors.transparent),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${mode.title(context)}. ${mode.hint(context)}',
      child: Material(
        color: c.surface,
        shape: _shape.copyWith(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: _shape,
          onTap: () => context.go(AppRoutes.play(mode)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 122),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(_modeIcons[mode], size: 28, color: c.highlight),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        mode.title(context),
                        style: TextStyle(
                          fontFamily: headingFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.hint(context),
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 13,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
