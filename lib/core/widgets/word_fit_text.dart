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

/// The height of [text] laid out in [maxWidth] at [fontSize].
double _textHeight({
  required String text,
  required TextStyle style,
  required double fontSize,
  required double maxWidth,
  required TextScaler textScaler,
  required TextDirection textDirection,
  required TextAlign textAlign,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(fontSize: fontSize),
    ),
    textDirection: textDirection,
    textAlign: textAlign,
    textScaler: textScaler,
  )..layout(maxWidth: maxWidth);
  final height = painter.height;
  painter.dispose();
  return height;
}

/// The largest font size, from [start] down to [minFontSize], at which [text]
/// wrapped in [maxWidth] is no taller than [maxHeight].
///
/// The text wraps the way [WordFitText] wraps it (between words only), and a
/// smaller size never makes a word wider, so a size that was chosen by
/// [fitWordFontSize] keeps its words whole. When even [minFontSize] is too
/// tall, [minFontSize] is returned.
double fitHeightFontSize({
  required String text,
  required TextStyle style,
  required double start,
  required double maxWidth,
  required double maxHeight,
  required double minFontSize,
  required TextScaler textScaler,
  TextDirection textDirection = TextDirection.ltr,
  TextAlign textAlign = TextAlign.center,
}) {
  if (!maxWidth.isFinite ||
      !maxHeight.isFinite ||
      maxWidth <= 0 ||
      maxHeight <= 0 ||
      start <= minFontSize) {
    return start;
  }
  double heightAt(double size) => _textHeight(
    text: text,
    style: style,
    fontSize: size,
    maxWidth: maxWidth,
    textScaler: textScaler,
    textDirection: textDirection,
    textAlign: textAlign,
  );

  var size = start;
  while (size > minFontSize && heightAt(size) > maxHeight) {
    size = math.max(size - 1, minFontSize);
  }
  return size;
}

/// A text that wraps between the words. It gets a smaller font size when a
/// single word would not fit in a line (see [fitWordFontSize]) and, when the
/// space it is given has a limited height, when the wrapped text would be
/// taller than that space (see [fitHeightFontSize]). If it does not fit even
/// at [minFontSize], it scrolls.
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
        var size = fitWordFontSize(
          text: text,
          style: style,
          maxWidth: constraints.maxWidth,
          minFontSize: minFontSize,
          textScaler: scaler,
          textDirection: direction,
        );
        size = fitHeightFontSize(
          text: text,
          style: style,
          start: size,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          minFontSize: minFontSize,
          textScaler: scaler,
          textDirection: direction,
          textAlign: textAlign,
        );
        final result = Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(fontSize: size),
        );
        final tooTall =
            constraints.maxHeight.isFinite &&
            constraints.maxWidth.isFinite &&
            _textHeight(
                  text: text,
                  style: style,
                  fontSize: size,
                  maxWidth: constraints.maxWidth,
                  textScaler: scaler,
                  textDirection: direction,
                  textAlign: textAlign,
                ) >
                constraints.maxHeight;
        return tooTall ? SingleChildScrollView(child: result) : result;
      },
    );
  }
}
