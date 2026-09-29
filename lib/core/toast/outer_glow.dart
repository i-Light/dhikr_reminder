import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Corner radius of the rounded rectangle the reminder card's glow layers
/// cast their outer-blur shadows from. Kept in sync with the card's own
/// `BorderRadius.circular(35)` — the glow is the card's outline, blurred.
const double kReminderGlowCornerRadius = 35;

/// Extra logical pixels [GlowSpriteStore] bakes around every sprite, so the
/// outward half of an outer-blur shadow — which lies entirely *outside* the
/// box it is cast from — survives rasterization instead of being clipped at
/// the sprite's own bounds.
///
/// `Picture.toImageSync` drops everything outside the image rectangle, and a
/// gaussian is visually done by roughly three standard deviations, which for
/// Flutter's blur is never more than the `blurRadius` itself. Padding by
/// `3 × blurRadius + spreadRadius` therefore leaves the sprite's own edges
/// at (visually) exactly zero — the falloff is fully contained, with no
/// second hard cut — while still covering the whole halo.
double glowSpritePadding({
  required double blurRadius,
  required double spreadRadius,
}) =>
    3 * blurRadius + spreadRadius;

/// Pre-rendered falloff sprites for the reminder card's two outer-glow
/// layers (the ambient backdrop glow and the tap pulse).
///
/// Both layers are `BoxShadow(blurStyle: BlurStyle.outer)` shapes painted
/// over a screen-sized rounded rectangle. A gaussian blur that big is one of
/// the most expensive draws in the card, and because `HolyDustBackground`
/// keeps a `.repeat()`ing ticker alive whenever a reminder is on screen, the
/// engine re-executes those blur passes on *every* frame — not just on the
/// frames where the card itself repaints. Baking the blur once and drawing a
/// texture afterwards is visually identical: a gaussian blur is linear in
/// colour, so blurring a solid white shape and tinting the result with
/// `BlendMode.modulate` gives exactly the same pixels as blurring the tinted
/// shape directly.
///
/// Sprites are white RGB with the falloff in alpha, so the same bake serves
/// both accent colours (in-progress gold and complete green) — only the tint
/// changes per draw. Each sprite is capped at 1200 physical pixels on its
/// longest edge; the content is a pure gaussian, so the downscale is
/// invisible and a 4K screen doesn't get a 4K texture.
class GlowSpriteStore {
  GlowSpriteStore({double devicePixelRatio = 1.0})
      : _devicePixelRatio = devicePixelRatio;

  /// Physical pixels per logical pixel the sprites are rasterized at.
  ///
  /// Assign it on every build (see `_DhikrReminderCardState.build`); a change
  /// throws the cached sprites away so the next draw re-bakes at the new
  /// density.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    _invalidate();
  }

  /// The size the current sprite set was baked for. A window resize changes
  /// it, which invalidates the set — glow geometry depends on the layer size.
  Size? _size;

  final Map<String, ui.Image> _sprites = {};

  /// Returns the white falloff sprite for a shadow of [blurRadius] and
  /// [spreadRadius] around a [kReminderGlowCornerRadius]-rounded rectangle
  /// of [size], baking it on first use.
  ///
  /// The image is larger than [size]: it covers [size] inflated by
  /// [glowSpritePadding] on every side so the shadow's outward falloff isn't
  /// clipped at the box's bounds (see [_bake]). The painters place it back
  /// with [_drawSprite], which lines the box outline up with [size] again.
  ui.Image sprite({
    required Size size,
    required double blurRadius,
    required double spreadRadius,
  }) {
    if (_size != size) {
      _invalidate();
      _size = size;
    }
    return _sprites.putIfAbsent(
      '$blurRadius|$spreadRadius',
      () => _bake(size, blurRadius, spreadRadius),
    );
  }

  /// Discards every cached sprite. Call from the owning card state's
  /// `dispose` once nothing will paint from it again.
  void dispose() {
    _invalidate();
    _size = null;
  }

  void _invalidate() {
    for (final image in _sprites.values) {
      image.dispose();
    }
    _sprites.clear();
  }

  static const double _maxBakeSide = 1200;

  ui.Image _bake(Size size, double blurRadius, double spreadRadius) {
    // Bake on a canvas padded by the shadow's reach (see
    // [glowSpritePadding]). An outer shadow lives entirely *outside* the box
    // it is cast from, and `Picture.toImageSync` rasterizes only
    // [0, 0, width, height] — "content outside these bounds is clipped".
    // Baking at the bare box size therefore threw the whole outward halo
    // away, cutting the glow off in a hard rectangle exactly on the card's
    // bounds (the visible "outer glow is cutoff" regression). The painters
    // place the padded sprite back with `Rect.fromLTRB(-pad, -pad, ...)`
    // (see [_drawSprite]), so the halo spills past the card again the way
    // the live `BoxShadow` decoration always did.
    final double pad = glowSpritePadding(
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
    final Size padded = Size(size.width + 2 * pad, size.height + 2 * pad);

    // Cap the raster on its longest edge. A gaussian has no high-frequency
    // content worth keeping, so a smaller bake scaled back up on draw is
    // indistinguishable from a native-resolution one.
    final double ratio = math.min(
      _devicePixelRatio,
      _maxBakeSide / math.max(padded.width, padded.height),
    );
    final int width = math.max(1, (padded.width * ratio).round());
    final int height = math.max(1, (padded.height * ratio).round());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(ratio);
    final painter = BoxDecoration(
      borderRadius: BorderRadius.circular(kReminderGlowCornerRadius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFFFFFF),
          blurStyle: BlurStyle.outer,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    ).createBoxPainter();
    painter.paint(canvas, Offset(pad, pad), ImageConfiguration(size: size));
    painter.dispose();
    return recorder.endRecording().toImageSync(width, height);
  }
}

/// Paints the reminder card's ambient backdrop glow — the three-shadow
/// stack that used to be the `AnimatedContainer` decoration of glow layer 1.
///
/// [progress] carries the eased `isComplete` transition that
/// `AnimatedContainer` used to run: 0 at the in-progress rest state, 1 once
/// complete, anything in between during the 1.5s ease. At both rest states
/// every shadow is a single sprite draw from the shared [GlowSpriteStore]
/// (no blur passes, no matter how often the dust ticker produces frames).
/// Only the in-between frames fall back to painting the lerped
/// `BoxDecoration` directly — pixel-identical to what `AnimatedContainer`
/// did, for the length of the transition and no longer.
class AmbientGlowPainter extends CustomPainter {
  AmbientGlowPainter({
    required this.store,
    required this.accent,
    required this.progress,
  });

  final GlowSpriteStore store;

  /// The palette accent the shadows are tinted with — switches to green the
  /// moment the reminder completes, same as before.
  final Color accent;

  /// 0 = in-progress rest state, 1 = complete rest state.
  final double progress;

  // Shadow strengths at the two rest states, mirroring [_decoration] — the
  // sprite draws and the live transition read from the same numbers.
  static const double _shadow28Alpha = 0.35;
  static const double _shadow60Alpha = 0.68;
  static const double _shadow10Alpha = 0.48;

  /// The exact decoration glow layer 1 used to animate between — the live
  /// path below paints this through `Decoration.lerp`, which is what
  /// `AnimatedContainer` itself used.
  static BoxDecoration _decoration(Color accent, {required bool isComplete}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kReminderGlowCornerRadius),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: isComplete ? _shadow28Alpha : 0),
          blurStyle: BlurStyle.outer,
          blurRadius: 28,
          spreadRadius: isComplete ? 1 : 0,
        ),
        BoxShadow(
          color: accent.withValues(alpha: isComplete ? 0 : _shadow60Alpha),
          blurStyle: BlurStyle.outer,
          blurRadius: 60,
        ),
        BoxShadow(
          color: accent.withValues(alpha: isComplete ? 0 : _shadow10Alpha),
          blurStyle: BlurStyle.outer,
          blurRadius: 10,
        ),
      ],
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (progress <= 0) {
      // In-progress rest state: the 60- and 10-blur shadows at full
      // strength. The 28-blur shadow sits at alpha 0 here and contributes
      // nothing, so — exactly like painting it transparent — it isn't drawn.
      _drawSprite(
        canvas,
        size,
        store.sprite(size: size, blurRadius: 60, spreadRadius: 0),
        accent.withValues(alpha: _shadow60Alpha),
        pad: glowSpritePadding(blurRadius: 60, spreadRadius: 0),
      );
      _drawSprite(
        canvas,
        size,
        store.sprite(size: size, blurRadius: 10, spreadRadius: 0),
        accent.withValues(alpha: _shadow10Alpha),
        pad: glowSpritePadding(blurRadius: 10, spreadRadius: 0),
      );
    } else if (progress >= 1) {
      // Complete rest state: only the tight 28-blur halo with its 1px
      // spread; the other two shadows are at alpha 0.
      _drawSprite(
        canvas,
        size,
        store.sprite(size: size, blurRadius: 28, spreadRadius: 1),
        accent.withValues(alpha: _shadow28Alpha),
        pad: glowSpritePadding(blurRadius: 28, spreadRadius: 1),
      );
    } else {
      // Mid-transition: paint the lerped decoration live, which is
      // byte-for-byte what the old AnimatedContainer recorded for these
      // frames anyway. Transient (one 1.5s ease) and never at rest.
      final decoration = BoxDecoration.lerp(
        _decoration(accent, isComplete: false),
        _decoration(accent, isComplete: true),
        progress,
      )!;
      final painter = decoration.createBoxPainter();
      painter.paint(canvas, Offset.zero, ImageConfiguration(size: size));
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant AmbientGlowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.store != store;
  }
}

/// Paints the duplicated "biggest" glow of glow layer 1b — one 60-blur
/// outer shadow whose alpha is `completion × _glowOpacity`, i.e. the eased
/// `isComplete` fade multiplied by the pulse that flashes on every tap.
///
/// The shadow's *colour* is constant for any given frame, so the whole
/// animation is just re-tinting the baked 60-blur sprite — no blur pass and
/// no opacity layer, which also keeps the arrangement the
/// `impeller_investigation.md` fix settled on (alpha folded into the
/// shadow's own value, never a `FadeTransition` around a lone shadow).
class PulseGlowPainter extends CustomPainter {
  PulseGlowPainter({
    required this.store,
    required this.accent,
    required this.alpha,
  });

  final GlowSpriteStore store;

  /// Tint of the pulse: the current palette accent.
  final Color accent;

  /// Combined strength — `completion × pulse`. `<= 0` draws nothing, which
  /// matches painting a fully transparent shadow.
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || alpha <= 0) return;
    _drawSprite(
      canvas,
      size,
      store.sprite(size: size, blurRadius: 60, spreadRadius: 0),
      accent.withValues(alpha: alpha),
      pad: glowSpritePadding(blurRadius: 60, spreadRadius: 0),
    );
  }

  @override
  bool shouldRepaint(covariant PulseGlowPainter oldDelegate) {
    return oldDelegate.alpha != alpha ||
        oldDelegate.accent != accent ||
        oldDelegate.store != store;
  }
}

/// Draws [sprite] placed so its baked box outline lands exactly on [size]:
/// the sprite covers [size] inflated by [pad] on every side (see
/// [glowSpritePadding]), so it is mapped onto `Rect.fromLTRB(-pad, -pad,
/// size.width + pad, size.height + pad)` and the padded ring of falloff
/// spills past the card. Painting outside [size] is intended — neither
/// `RenderCustomPaint` nor the card's `Stack` clips, exactly like the live
/// `BoxShadow` decoration did before the glow was baked.
///
/// The tint multiplies through `BlendMode.modulate`: the sprite's white
/// falloff picks up the tint's RGB and its alpha rides the tint's, which is
/// what colouring a `BoxShadow` used to do implicitly.
void _drawSprite(
  Canvas canvas,
  Size size,
  ui.Image sprite,
  Color tint, {
  required double pad,
}) {
  canvas.drawImageRect(
    sprite,
    Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
    Rect.fromLTRB(-pad, -pad, size.width + pad, size.height + pad),
    Paint()..colorFilter = ColorFilter.mode(tint, BlendMode.modulate),
  );
}
