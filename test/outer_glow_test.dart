import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dhikr_reminder/core/toast/outer_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression tests for the outer glow the reminder card bakes once and
// redraws every frame (see GlowSpriteStore).
//
// The bake rasterizes an *outer* `BoxShadow` with `Picture.toImageSync`,
// which clips everything outside the image bounds — but an outer shadow
// lives entirely outside the box it is cast from. Baking at the bare box
// size (the sprite store's first cut) therefore threw the outward falloff
// away and cut the glow off in a hard rectangle exactly on the card's
// bounds. These tests pin both halves of the fix: the halo must be present
// just outside the box, and must have faded to nothing at the sprite's own
// (padded) edges.
const _card = Size(200, 100);
const _blur = 60.0;
const _spread = 0.0;

/// Alpha channel of a 1:1-rasterized sprite/picture at logical (x, y).
/// Both tests bake with `devicePixelRatio` 1 at sizes under the store's
/// 1200-pixel bake cap, so logical pixels and image pixels coincide.
int _alphaAt(ByteData rgba, int imageWidth, double x, double y) {
  final offset = (y.round() * imageWidth + x.round()) * 4 + 3;
  return rgba.getUint8(offset);
}

Future<ByteData> _rgbaOf(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(data, isNotNull, reason: 'CPU-rasterized test images support rawRgba');
  return data!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `flutter test` boots the automated binding with `debugDisableShadows`
  // on, which strips the blur's mask filter and clips outer shadows to
  // their box (see `BoxShadow.toPaint` / `_BoxDecorationPainter._paintShadows`)
  // — precisely the pixels this file asserts on. Force real shadows for
  // each test and put the binding's value back afterwards.
  late bool savedDisableShadows;
  setUp(() {
    savedDisableShadows = debugDisableShadows;
    debugDisableShadows = false;
  });
  tearDown(() {
    debugDisableShadows = savedDisableShadows;
  });

  test('baked glow sprite keeps the outward falloff and contains it', () async {
    final store = GlowSpriteStore(devicePixelRatio: 1);
    addTearDown(store.dispose);

    final pad = glowSpritePadding(blurRadius: _blur, spreadRadius: _spread);
    final sprite = store.sprite(
      size: _card,
      blurRadius: _blur,
      spreadRadius: _spread,
    );

    // The sprite spans the box plus the padding on every side...
    expect(sprite.width, (_card.width + 2 * pad).round());
    expect(sprite.height, (_card.height + 2 * pad).round());

    final rgba = await _rgbaOf(sprite);
    final midX = pad + _card.width / 2;
    final midY = pad + _card.height / 2;

    // Ten logical pixels outside each edge — the halo at nearly full
    // strength. This is exactly the band the un-padded bake clipped away.
    const visible = 25;
    expect(
      _alphaAt(rgba, sprite.width, pad - 10, midY),
      greaterThan(visible),
      reason: 'the halo must exist to the left of the card',
    );
    expect(
      _alphaAt(rgba, sprite.width, pad + _card.width + 10, midY),
      greaterThan(visible),
      reason: 'the halo must exist to the right of the card',
    );
    expect(
      _alphaAt(rgba, sprite.width, midX, pad - 10),
      greaterThan(visible),
      reason: 'the halo must exist above the card',
    );
    expect(
      _alphaAt(rgba, sprite.width, midX, pad + _card.height + 10),
      greaterThan(visible),
      reason: 'the halo must exist below the card',
    );

    // At the sprite's own border the gaussian has faded to nothing, so the
    // padding introduces no second hard edge of its own.
    const quiet = 3;
    expect(
      _alphaAt(rgba, sprite.width, 0, midY),
      lessThan(quiet),
      reason: 'falloff reaches zero before the left sprite edge',
    );
    expect(
      _alphaAt(rgba, sprite.width, (sprite.width - 1).toDouble(), midY),
      lessThan(quiet),
      reason: 'falloff reaches zero before the right sprite edge',
    );
    expect(
      _alphaAt(rgba, sprite.width, midX, 0),
      lessThan(quiet),
      reason: 'falloff reaches zero before the top sprite edge',
    );
    expect(
      _alphaAt(rgba, sprite.width, midX, (sprite.height - 1).toDouble()),
      lessThan(quiet),
      reason: 'falloff reaches zero before the bottom sprite edge',
    );
    expect(
      _alphaAt(rgba, sprite.width, 0, 0),
      lessThan(quiet),
      reason: 'the sprite corner stays transparent',
    );
  });

  test('AmbientGlowPainter paints the halo past the card bounds', () async {
    final store = GlowSpriteStore(devicePixelRatio: 1);
    addTearDown(store.dispose);

    final pad = glowSpritePadding(blurRadius: _blur, spreadRadius: _spread);
    final painter = AmbientGlowPainter(
      store: store,
      accent: const Color.fromARGB(255, 231, 170, 72),
      progress: 0, // in-progress rest state: the 60- + 10-blur sprite stack
    );

    // Same arrangement as the card's `Positioned.fill` CustomPaint: the
    // painter receives `size`, and its out-of-`size` painting must survive
    // — nothing in the card's tree clips it (that was the whole bug).
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(pad, pad); // card-local (0,0) → sprite-space (pad, pad)
    painter.paint(canvas, _card);

    final image = recorder.endRecording().toImageSync(
          (_card.width + 2 * pad).round(),
          (_card.height + 2 * pad).round(),
        );
    addTearDown(image.dispose);

    final rgba = await _rgbaOf(image);
    final midX = pad + _card.width / 2;
    final midY = pad + _card.height / 2;

    // 10px left of the card: 60-blur falloff (~0.39) × the layer's 0.68
    // tint through `BlendMode.modulate` → roughly 67/255, plus a little
    // from the 10-blur shadow.
    expect(
      _alphaAt(rgba, image.width, pad - 10, midY),
      greaterThan(20),
      reason: 'the glow must extend beyond the card, not stop at its bounds',
    );

    // ...while the padded canvas border is already silence: the halo ends
    // by fading, never by being cut.
    expect(
      _alphaAt(rgba, image.width, 0, midY),
      lessThan(3),
      reason: 'no glow is left at the padded left edge',
    );
    expect(
      _alphaAt(rgba, image.width, midX, 0),
      lessThan(3),
      reason: 'no glow is left at the padded top edge',
    );
    expect(
      _alphaAt(rgba, image.width, (image.width - 1).toDouble(), midY),
      lessThan(3),
      reason: 'no glow is left at the padded right edge',
    );
  });
}
