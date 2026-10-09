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

/// The transliteration under the Arabic is this much of the Arabic's size, and
/// never smaller than [kTransliterationMinFontSize] so a long dhikr does not
/// shrink it past reading.
const double kTransliterationRatio = 0.55;
const double kTransliterationMinFontSize = 13;

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

/// One run of text in a stack that is sized as a whole: the Arabic, or the
/// transliteration under it.
///
/// Every block's size follows the first block's: the block at index 0 gets the
/// size the search finds ([scale] 1), the others get a [scale] of it, never
/// below [minFontSize].
@immutable
class DhikrTextBlock {
  const DhikrTextBlock({
    required this.text,
    required this.style,
    this.textDirection,
    this.scale = 1,
    this.minFontSize = _minFontSize,
  });

  final String text;

  /// Everything that affects layout (family, line height, spacing) and nothing
  /// that does not (shadows, colour). Its `fontSize` is ignored.
  final TextStyle style;

  /// The block's own direction, or null to use the ambient one. The Arabic is
  /// right to left and the transliteration left to right, whatever the app's
  /// language is.
  final TextDirection? textDirection;

  final double scale;
  final double minFontSize;

  double fontSizeFor(double base) => math.max(minFontSize, base * scale);

  @override
  bool operator ==(Object other) =>
      other is DhikrTextBlock &&
      other.text == text &&
      other.style == style &&
      other.textDirection == textDirection &&
      other.scale == scale &&
      other.minFontSize == minFontSize;

  @override
  int get hashCode =>
      Object.hash(text, style, textDirection, scale, minFontSize);
}

/// The biggest size for the first of [blocks] at which all of them, stacked
/// with [gap] between, still fit inside [box] — then scaled down by
/// [dhikrFillRatio] (counted on the first block's words) so that a handful of
/// words does not balloon to fill it.
///
/// "Fits" means both that the stack is no taller than the box and that no single
/// word is wider than it (Flutter would otherwise break the word mid-glyph,
/// which for Arabic is never what anyone wants to see). Measured with
/// [TextScaler.noScaling]; callers must render the result with the same, or the
/// text they draw is not the text that was measured.
///
/// The answer is the size of the first block; use [DhikrTextBlock.fontSizeFor]
/// for the others. When even the smallest size does not fit, the smallest comes
/// back and it is the caller's business to scale the stack down (see
/// [DhikrFitStack]).
double fitDhikrStackFontSize({
  required List<DhikrTextBlock> blocks,
  required Size box,
  required TextDirection textDirection,
  double gap = 0,
  double minFillRatio = kDhikrMinFillRatio,
  int fullFillWords = kDhikrFullFillWords,
  double maxFontSize = _maxFontSize,
}) {
  final live = [
    for (final block in blocks)
      if (block.text.trim().isNotEmpty) block,
  ];
  if (!box.width.isFinite || !box.height.isFinite) return _minFontSize;
  if (box.width <= 0 || box.height <= 0 || live.isEmpty) return _minFontSize;

  bool fits(double base) {
    var height = gap * (live.length - 1);
    for (final block in live) {
      final painter = TextPainter(
        text: TextSpan(
          text: block.text,
          style: block.style.copyWith(fontSize: block.fontSizeFor(base)),
        ),
        textDirection: block.textDirection ?? textDirection,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: box.width);
      final widest = painter
          .computeLineMetrics()
          .fold<double>(0, (widest, line) => math.max(widest, line.width));
      height += painter.height;
      painter.dispose();
      if (widest > box.width) return false;
    }
    return height <= box.height;
  }

  var low = _minFontSize;
  var high = math.max(low, maxFontSize);
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

  final wordCount = live.first.text.trim().split(RegExp(r'\s+')).length;
  final ratio = dhikrFillRatio(
    wordCount,
    minFillRatio: minFillRatio,
    fullFillWords: fullFillWords,
  );
  return math.max(_minFontSize, low * ratio);
}

/// The biggest font size at which [text], laid out in [style], still fits
/// inside [box] — then scaled down by [dhikrFillRatio] so that a handful of
/// words does not balloon to fill it.
///
/// [style] should carry everything that affects layout — family, line height,
/// word spacing — and nothing that doesn't (shadows, colour); its `fontSize` is
/// ignored. See [fitDhikrStackFontSize] for what "fits" means.
double fitDhikrFontSize({
  required String text,
  required TextStyle style,
  required Size box,
  required TextDirection textDirection,
  double minFillRatio = kDhikrMinFillRatio,
  int fullFillWords = kDhikrFullFillWords,
}) {
  return fitDhikrStackFontSize(
    blocks: [DhikrTextBlock(text: text, style: style)],
    box: box,
    textDirection: textDirection,
    minFillRatio: minFillRatio,
    fullFillWords: fullFillWords,
  );
}

/// A [DhikrTextBlock] together with how to draw it once its size is known.
@immutable
class DhikrFitBlock {
  const DhikrFitBlock({required this.block, required this.builder});

  final DhikrTextBlock block;

  /// Draws the text at the size that was found. Render with
  /// [TextScaler.noScaling] so it matches the measurement.
  final Widget Function(BuildContext context, double fontSize) builder;
}

/// Sizes a column of text blocks (the Arabic, and under it the transliteration)
/// to their available space and draws them.
///
/// The search lays the text out a dozen-plus times, and this widget's parent
/// rebuilds on every tap (the count changes), so the answer is remembered per
/// text/box/style rather than recomputed each build.
///
/// A stack that still does not fit at the smallest size (a very long dhikr with
/// a transliteration under it) is scaled down as a whole rather than spilling
/// out of its box.
class DhikrFitStack extends StatefulWidget {
  const DhikrFitStack({
    super.key,
    required this.blocks,
    this.gap = 0,
    this.reserve = EdgeInsets.zero,
    this.maxFontSize = _maxFontSize,
    this.minFillRatio = kDhikrMinFillRatio,
  });

  final List<DhikrFitBlock> blocks;

  /// The biggest size the first block may get, however much room there is.
  final double maxFontSize;

  /// See [dhikrFillRatio]. `1` lets a short dhikr use all the room it can.
  final double minFillRatio;

  /// Space between two blocks.
  final double gap;

  /// Space inside the incoming constraints the text must stay out of — the
  /// card's ornaments and hint row sit there.
  final EdgeInsets reserve;

  @override
  State<DhikrFitStack> createState() => _DhikrFitStackState();
}

class _DhikrFitStackState extends State<DhikrFitStack> {
  Object? _cacheKey;
  double _cachedSize = _minFontSize;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final blocks = [for (final b in widget.blocks) b.block];
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(
          math.max(0, constraints.maxWidth - widget.reserve.horizontal),
          math.max(0, constraints.maxHeight - widget.reserve.vertical),
        );
        final key = Object.hash(
          Object.hashAll(blocks),
          widget.gap,
          widget.maxFontSize,
          widget.minFillRatio,
          box,
          direction,
        );
        if (key != _cacheKey) {
          _cacheKey = key;
          _cachedSize = fitDhikrStackFontSize(
            blocks: blocks,
            box: box,
            gap: widget.gap,
            textDirection: direction,
            maxFontSize: widget.maxFontSize,
            minFillRatio: widget.minFillRatio,
          );
        }
        final children = <Widget>[];
        for (final entry in widget.blocks) {
          if (entry.block.text.trim().isEmpty) continue;
          if (children.isNotEmpty) children.add(SizedBox(height: widget.gap));
          children.add(
            entry.builder(context, entry.block.fontSizeFor(_cachedSize)),
          );
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: box.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
