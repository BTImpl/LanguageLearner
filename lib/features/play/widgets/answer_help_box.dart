import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';
import 'package:languagelearner/app/theme/app_theme.dart';
import 'package:languagelearner/core/widgets/app_card.dart';
import 'package:languagelearner/core/widgets/app_shapes.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// The right answer, with a countdown and a bar that runs out in [duration].
/// Shared by the exact-match and the speaking game.
/// A new [revision] (help asked again) starts the countdown over.
class AnswerHelpBox extends StatefulWidget {
  const AnswerHelpBox({
    required this.text,
    required this.revision,
    required this.duration,
    super.key,
  });

  final String text;
  final int revision;
  final Duration duration;

  @override
  State<AnswerHelpBox> createState() => _AnswerHelpBoxState();
}

class _AnswerHelpBoxState extends State<AnswerHelpBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void didUpdateWidget(AnswerHelpBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        color: c.surfaceRaised,
        borderColor: c.highlight,
        borderRadius: AppRadii.choice,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final totalMs = widget.duration.inMilliseconds;
            final leftMs = (totalMs * (1 - _controller.value)).round();
            final ceiling = (leftMs / 1000).ceil();
            final seconds = ceiling < 1 ? 1 : ceiling;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          fontFamily: headingFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.i18n.typingHelpCountdown(seconds),
                      style: TextStyle(
                        fontFamily: bodyFontFamily,
                        fontSize: 14,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 1 - _controller.value,
                    minHeight: 4,
                    backgroundColor: c.line,
                    color: c.highlight,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
