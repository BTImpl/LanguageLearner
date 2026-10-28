import 'dart:math' as math;

import 'package:flutter/material.dart';

// A line may break after a space or after a hyphen, never inside a word.
final _wordBreak = RegExp(r'\s+|(?<=-)');

// A word that is exactly as wide as the line may still be broken by rounding
// in the text layout, so the words get this much less room.
const _safety = 1.0;

/// The font size at which the widest word of [text] fits in [maxWidth], but no
/// larger than the size of [style] and no smaller than [minFontSize].
///
/// Only a single word that is wider than the line makes the size smaller: a
/// text of several short words stays at the full size and wraps between the
/// words. A word that does not fit even at [minFontSize] gets that size, and
/// the line breaks inside it.
double fitWordFontSize({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required double minFontSize,
  required TextScaler textScaler,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final base = style.fontSize!;
  final room = maxWidth - _safety;
  if (!maxWidth.isFinite || maxWidth <= 0 || base <= minFontSize || room <= 0) {
    return base;
  }
  final words = text.split(_wordBreak).where((word) => word.isNotEmpty);

  double widest(double fontSize) {
    var result = 0.0;
    for (final word in words) {
      final painter = TextPainter(
        text: TextSpan(
          text: word,
          style: style.copyWith(fontSize: fontSize),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      result = math.max(result, painter.width);
      painter.dispose();
    }
    return result;
  }

  final width = widest(base);
  if (width <= room) {
    return base;
  }
  // The width grows with the size; the loop corrects what rounding and a
  // non-linear text scaler leave over.
  var size = (base * room / width).floorToDouble().clamp(minFontSize, base);
  while (size > minFontSize && widest(size) > room) {
    size -= 1;
  }
  return size.clamp(minFontSize, base);
}

/// A text that wraps between the words and gets a smaller font size only when
/// a single word would not fit in a line (see [fitWordFontSize]).
class WordFitText extends StatelessWidget {
  const WordFitText(
    this.text, {
    required this.style,
    this.minFontSize = 24,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final String text;

  /// The full size; its `fontSize` is required.
  final TextStyle style;
  final double minFontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = fitWordFontSize(
          text: text,
          style: style,
          maxWidth: constraints.maxWidth,
          minFontSize: minFontSize,
          textScaler: scaler,
          textDirection: direction,
        );
        return Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }
}
