import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:languagelearner/app/routes.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The entry of the quiz made from a photo, under the practice modes. It does
/// not depend on the deck: the questions come from the photo.
class PhotoQuizTile extends StatelessWidget {
  const PhotoQuizTile({super.key});

  static const _shape = RoundedRectangleBorder(borderRadius: AppRadii.card);

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final c = context.colors;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '${i18n.photoQuizTitle}. ${i18n.photoQuizHomeSubtitle}. '
          '${i18n.photoQuizNewBadge}',
      child: Material(
        color: c.surface,
        shape: _shape.copyWith(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: _shape,
          onTap: () => context.go(AppRoutes.photoQuiz),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: AppRadii.small,
                  ),
                  child: Icon(Icons.photo_camera_outlined, color: c.highlight),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.photoQuizTitle,
                        style: TextStyle(
                          fontFamily: headingFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i18n.photoQuizHomeSubtitle,
                        style: TextStyle(
                          fontFamily: bodyFontFamily,
                          fontSize: 14,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    i18n.photoQuizNewBadge,
                    style: TextStyle(
                      fontFamily: bodyFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.onPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
