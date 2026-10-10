import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum CardCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

class DynamicOrnateCard extends StatelessWidget {
  const DynamicOrnateCard({
    super.key,
    required this.cornerPath,
    this.sourceCorner = CardCorner.topRight,
    this.colorize = true,
    this.outerPadding = EdgeInsets.zero,
    this.innerPadding =
        const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
    this.nominalCornerSize = const Size(120, 120),
    this.goldColor = const Color.fromARGB(255, 233, 199, 88),
    this.centerBumpAnimation, // <-- 1. Add this property
    required this.child,
  });
  final String cornerPath;
  final CardCorner sourceCorner;
  final bool colorize;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  final Size nominalCornerSize;
  final Color goldColor;
  final Widget child;
  final Animation<double>? centerBumpAnimation; // <-- 2. Declare the property

  bool _isRight(CardCorner corner) =>
      corner == CardCorner.topRight || corner == CardCorner.bottomRight;

  bool _isBottom(CardCorner corner) =>
      corner == CardCorner.bottomLeft || corner == CardCorner.bottomRight;

  bool _isCenter(CardCorner corner) => corner == CardCorner.center;

  Widget _buildCorner({
    required CardCorner targetCorner,
    required double margin,
    double? marginWidth,
    required double width,
    required double height,
  }) {
    final Color cornerColor = goldColor.withValues(
        alpha: _isCenter(targetCorner) ? 0.35 : goldColor.a + 0.2);
    final bool flipX = !_isCenter(targetCorner) &&
        (_isRight(targetCorner) != _isRight(sourceCorner));
    final bool flipY = !_isCenter(targetCorner) &&
        (_isBottom(targetCorner) != _isBottom(sourceCorner));

    Widget svg = BakedSvg(
      asset: _isCenter(targetCorner)
          ? 'assets/images/mandala_background.svg'
          : cornerPath,
      color: colorize ? cornerColor : null,
      width: width,
      height: height,
    );

    if (flipX || flipY) {
      svg = Transform.flip(
        flipX: flipX,
        flipY: flipY,
        child: svg,
      );
    }

    // <-- 3. Animate ONLY the center element
    if (_isCenter(targetCorner) && centerBumpAnimation != null) {
      svg = ScaleTransition(
        scale: centerBumpAnimation!,
        child: svg,
      );
    }

    List<double?> margins = [
      !_isBottom(targetCorner) ? margin : null,
      _isBottom(targetCorner) ? margin : null,
      !_isRight(targetCorner) ? margin : null,
      _isRight(targetCorner) ? margin : null,
    ];
    if (_isCenter(targetCorner)) {
      margins = [
        margin - height * 0.5,
        null,
        (marginWidth ?? 0) - width * 0.5,
        null
      ];
    }

    return Positioned(
      top: margins[0],
      bottom: margins[1],
      left: margins[2],
      right: margins[3],
      width: width,
      height: height,
      child: svg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: outerPadding,
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(
      //     color: goldColor.withValues(alpha: 0.4),
      //     width: 1.5,
      //   ),
      // ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Scaled Corner Layer
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final double h = constraints.maxHeight;

                if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
                  return const SizedBox.shrink();
                }

                final double maxW = w / 2;
                final double maxH = h / 2;

                final double scaleFactor = math.min(
                  1.0,
                  math.min(maxW / nominalCornerSize.width,
                      maxH / nominalCornerSize.height),
                );

                final double cornerW = nominalCornerSize.width * scaleFactor;
                final double cornerH = nominalCornerSize.height * scaleFactor;
                final double margin = (4.0 * scaleFactor).clamp(0.0, 4.0);

                final double cornerOpacity =
                    ((scaleFactor - 0.15) / 0.25).clamp(0.0, 1.0);

                if (cornerOpacity <= 0) return const SizedBox.shrink();

                return Opacity(
                  opacity: cornerOpacity,
                  child: Stack(
                    children: [
                      _buildCorner(
                        targetCorner: CardCorner.center,
                        margin: maxH,
                        marginWidth: maxW,
                        width: math.min(maxW, maxH) * 1.6,
                        height: math.min(maxW, maxH) * 1.6,
                      ),
                      _buildCorner(
                        targetCorner: CardCorner.topLeft,
                        margin: margin,
                        width: cornerW,
                        height: cornerH,
                      ),
                      _buildCorner(
                        targetCorner: CardCorner.topRight,
                        margin: margin,
                        width: cornerW,
                        height: cornerH,
                      ),
                      _buildCorner(
                        targetCorner: CardCorner.bottomLeft,
                        margin: margin,
                        width: cornerW,
                        height: cornerH,
                      ),
                      _buildCorner(
                        targetCorner: CardCorner.bottomRight,
                        margin: margin,
                        width: cornerW,
                        height: cornerH,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 2. Foreground Content
          Padding(
            padding: innerPadding,
            child: child,
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            // alignment: AlignmentGeometry.bottomCenter,
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: goldColor.withValues(
                      alpha:
                          0.5), //theme.textTheme.bodyLarge?.color!.withAlpha(90),
                  size: 32,
                ),
                Text(
                  l10n.dhikrReminderTouchEverywhereTip,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    // Brighter than the ornament beside it: at half strength
                    // the words were about 2.5:1 against the card, too faint
                    // to read for many people.
                    color: goldColor.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An SVG that is drawn as a picture of itself rather than as vector shapes.
///
/// The card's mandala is half a megabyte of gradient-filled paths, and painted
/// through a colour filter (which flattens every one of those gradients into the
/// one gold anyway) it costs a layer and hundreds of shapes on every frame the
/// card repaints, which is every tap. So it is drawn live only until the first
/// frame is on screen; then it is turned into an image once, at the size it is
/// shown at, kept for the app's lifetime and drawn as one textured rectangle
/// from there on. The reminder window is pre-warmed at startup (see
/// `ReminderPrewarmSurface`), so the first real reminder already has it.
class BakedSvg extends StatefulWidget {
  const BakedSvg({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    this.color,
  });

  final String asset;

  /// Paints every shape of the SVG this one colour (keeping its shape and
  /// transparency), or null to keep the SVG's own colours.
  final Color? color;

  final double width;
  final double height;

  /// Drops every baked image. For tests.
  @visibleForTesting
  static void clearCache() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  static final Map<String, ui.Image> _cache = {};

  /// Longest side, in physical pixels, an image is baked at: more than a card
  /// ornament can show, and bounded however large the screen is.
  static const double _maxSide = 1024;

  @override
  State<BakedSvg> createState() => _BakedSvgState();
}

class _BakedSvgState extends State<BakedSvg> {
  final GlobalKey _boundary = GlobalKey();
  bool _baking = false;

  double _pixelRatio = 1;

  String get _key {
    // Sizes within 8 logical pixels share an image: a window that is a pixel or
    // two different must not bake it all over again.
    final w = (widget.width / 8).round();
    final h = (widget.height / 8).round();
    return '${widget.asset}|${widget.color?.toARGB32()}|$w|$h|$_pixelRatio';
  }

  void _bake() {
    if (_baking || BakedSvg._cache.containsKey(_key)) return;
    _baking = true;
    final key = _key;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final render = _boundary.currentContext?.findRenderObject();
        if (render is! RenderRepaintBoundary || !render.hasSize) return;
        final longest = math.max(render.size.width, render.size.height);
        final ratio = math.min(_pixelRatio, BakedSvg._maxSide / longest);
        final image = await render.toImage(pixelRatio: ratio);
        if (BakedSvg._cache.containsKey(key)) {
          image.dispose();
        } else {
          BakedSvg._cache[key] = image;
        }
        if (mounted) setState(() {});
      } catch (_) {
        // Stays live: it only costs the frames it always cost.
      } finally {
        _baking = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final baked = BakedSvg._cache[_key];
    if (baked != null) {
      return RawImage(
        image: baked,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }
    _bake();
    final color = widget.color;
    return RepaintBoundary(
      key: _boundary,
      child: SvgPicture.asset(
        widget.asset,
        colorFilter:
            color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
    );
  }
}
