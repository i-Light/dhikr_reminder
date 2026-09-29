import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How much of the "as big as it can be" size a one-word dhikr is allowed to
/// use. Without this a short phrase would be blown up until it touches the
/// card's edges, which reads as shouting rather than as a reminder.
///
/// `1.0` disables the cap entirely (every dhikr is as large as its box
/// permits); lower values keep short phrases smaller.
const double kDhikrMinFillRatio = 0.6;

/// The word count at and above which a dhikr is sized to fill its box
/// completely. Between one word and this many, the fill ratio climbs linearly
/// from [kDhikrMinFillRatio] up to `1.0`.
const int kDhikrFullFillWords = 10;

/// Font-size bounds for the search. The floor keeps a paragraph-length entry
/// legible instead of shrinking forever; the ceiling just bounds the search.
const double _minFontSize = 14;
const double _maxFontSize = 600;

/// Fraction of the box a dhikr of [wordCount] words should fill, in
/// `[minFillRatio, 1]` — see [kDhikrMinFillRatio] and [kDhikrFullFillWords].
double dhikrFillRatio(
  int wordCount, {
  double minFillRatio = kDhikrMinFillRatio,
  int fullFillWords = kDhikrFullFillWords,
}) {
  if (fullFillWords <= 1) return 1;
  final t = ((wordCount - 1) / (fullFillWords - 1)).clamp(0.0, 1.0);
  return minFillRatio + (1 - minFillRatio) * t;
}

/// The biggest font size at which [text], laid out in [style], still fits
/// inside [box] — then scaled down by [dhikrFillRatio] so that a handful of
/// words does not balloon to fill it.
///
/// "Fits" means both that the wrapped block is no taller than the box and that
/// no single word is wider than it (Flutter would otherwise break the word
/// mid-glyph, which for Arabic is never what anyone wants to see). [style]
/// should carry everything that affects layout — family, line height, word
/// spacing — and nothing that doesn't (shadows, colour); its `fontSize` is
/// ignored.
///
/// Measured with [TextScaler.noScaling]; callers must render the result with
/// the same, or the text they draw is not the text that was measured.
double fitDhikrFontSize({
  required String text,
  required TextStyle style,
  required Size box,
  required TextDirection textDirection,
  double minFillRatio = kDhikrMinFillRatio,
  int fullFillWords = kDhikrFullFillWords,
}) {
  if (!box.width.isFinite || !box.height.isFinite) return _minFontSize;
  if (box.width <= 0 || box.height <= 0 || text.trim().isEmpty) {
    return _minFontSize;
  }

  bool fits(double fontSize) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(fontSize: fontSize)),
      textDirection: textDirection,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: box.width);
    final widest = painter
        .computeLineMetrics()
        .fold<double>(0, (widest, line) => math.max(widest, line.width));
    final result = painter.height <= box.height && widest <= box.width;
    painter.dispose();
    return result;
  }

  var low = _minFontSize;
  var high = _maxFontSize;
  if (fits(high)) {
    low = high;
  } else {
    // ~0.05px of resolution after 14 halvings of a ~600px range.
    for (var i = 0; i < 14; i++) {
      final mid = (low + high) / 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }
  }

  final wordCount = text.trim().split(RegExp(r'\s+')).length;
  final ratio = dhikrFillRatio(
    wordCount,
    minFillRatio: minFillRatio,
    fullFillWords: fullFillWords,
  );
  return math.max(_minFontSize, low * ratio);
}

/// Sizes [text] to its available space and hands the result to [builder].
///
/// The search lays the text out a dozen-plus times, and this widget's parent
/// rebuilds on every tap (the count changes), so the answer is remembered per
/// text/box/style rather than recomputed each build.
class DhikrFitText extends StatefulWidget {
  const DhikrFitText({
    super.key,
    required this.text,
    required this.style,
    required this.builder,
    this.reserve = EdgeInsets.zero,
  });

  final String text;

  /// The layout-affecting style used to measure; see [fitDhikrFontSize].
  final TextStyle style;

  /// Space inside the incoming constraints the text must stay out of — the
  /// card's ornaments and hint row sit there.
  final EdgeInsets reserve;

  /// Builds the actual text at the size that was found. Render with
  /// [TextScaler.noScaling] so it matches the measurement.
  final Widget Function(BuildContext context, double fontSize) builder;

  @override
  State<DhikrFitText> createState() => _DhikrFitTextState();
}

class _DhikrFitTextState extends State<DhikrFitText> {
  Object? _cacheKey;
  double _cachedSize = _minFontSize;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(
          math.max(0, constraints.maxWidth - widget.reserve.horizontal),
          math.max(0, constraints.maxHeight - widget.reserve.vertical),
        );
        final key = Object.hash(widget.text, box, widget.style, direction);
        if (key != _cacheKey) {
          _cacheKey = key;
          _cachedSize = fitDhikrFontSize(
            text: widget.text,
            style: widget.style,
            box: box,
            textDirection: direction,
          );
        }
        return widget.builder(context, _cachedSize);
      },
    );
  }
}
