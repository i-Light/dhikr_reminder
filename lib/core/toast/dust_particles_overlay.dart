import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Stop positions across a glowing particle's halo, in fractions of its
/// total extent (see [_glowFalloff]).
const List<double> _glowStops = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

/// The gaussian falloff sampled at [_glowStops]: `exp(-7.58 t²)`, where `t`
/// is the fraction of the way out from the halo's centre. Constant for every
/// particle because the extent/sigma ratio of the old blur was fixed (see
/// [HolyDustPainter.paint]).
const List<double> _glowFalloff = [1.0, 0.738, 0.297, 0.065, 0.008, 0.0];

/// Peak alpha of the halo as a fraction of the particle's current alpha:
/// `0.35` (the pre-blur paint alpha) times `1 - exp(-a²/2σ²) ≈ 0.33`, the
/// centre value a gaussian blur leaves on a disc of radius `a = 2.5r` when
/// blurred with `σ = 2.8r` — i.e. the brightest point of the old
/// mask-filtered halo, kept identical.
const double _glowPeakFactor = 0.35 * 0.33;

class DustParticle {
  DustParticle({
    required this.x0,
    required this.y0,
    required this.radius,
    required this.baseOpacity,
    required this.speedY,
    required this.wobbleFreq,
    required this.wobbleAmp,
    required this.twinkleFreq,
    required this.phase,
    required this.hasGlow,
    required this.color,
  });

  factory DustParticle.random(math.Random rand, List<Color> palette) {
    return DustParticle(
      x0: rand.nextDouble(),
      y0: rand.nextDouble(),
      radius: 1.1 + rand.nextDouble() * 2.5, // Sizes between 0.8px and 3.0px
      baseOpacity: 0.2 + rand.nextDouble() * 0.75,
      speedY: 0.015 + rand.nextDouble() * 0.035, // Slow upward drift
      wobbleFreq: 0.8 + rand.nextDouble() * 1.5,
      wobbleAmp: 0.004 + rand.nextDouble() * 0.012, // Subtle horizontal sway
      twinkleFreq: 1.0 + rand.nextDouble() * 2.5,
      phase: rand.nextDouble() * math.pi * 2,
      hasGlow: rand.nextDouble() < 0.45, // % of particles have a soft halo
      color: palette[rand.nextInt(palette.length)],
    );
  }

  final double x0;
  final double y0;
  final double radius;
  final double baseOpacity;
  final double speedY;
  final double wobbleFreq;
  final double wobbleAmp;
  final double twinkleFreq;
  final double phase;
  final bool hasGlow;
  final Color color;
}

/// The side, in pixels, of the halo sprite: a white disc whose alpha falls off
/// like the gaussian above. Every halo is this one image, scaled and tinted.
const int _haloSide = 64;

ui.Image? _haloSprite;

/// The shared halo sprite, baked on first use (see [_glowFalloff]).
ui.Image _halo() {
  final existing = _haloSprite;
  if (existing != null) return existing;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const half = _haloSide / 2;
  canvas.drawCircle(
    const Offset(half, half),
    half,
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(half, half),
        half,
        [
          for (final falloff in _glowFalloff)
            Color.fromRGBO(255, 255, 255, falloff),
        ],
        _glowStops,
      ),
  );
  return _haloSprite =
      recorder.endRecording().toImageSync(_haloSide, _haloSide);
}

class HolyDustPainter extends CustomPainter {
  HolyDustPainter({
    required Listenable animation,
    required this.particles,
    required this.stopwatch,
  })  : _corePaint = Paint()..style = PaintingStyle.fill,
        _glowPaint = Paint(),
        _glowers = [
          for (final p in particles)
            if (p.hasGlow) p,
        ],
        super(repaint: animation) {
    final n = _glowers.length;
    _transforms = Float32List(n * 4);
    _rects = Float32List(n * 4);
    _colors = Int32List(n);
    for (var i = 0; i < n; i++) {
      _rects[i * 4 + 2] = _haloSide.toDouble();
      _rects[i * 4 + 3] = _haloSide.toDouble();
    }
  }

  final List<DustParticle> particles;
  final Stopwatch stopwatch;

  // Reused for every frame: nothing is allocated while the card is open.
  final Paint _corePaint;
  final Paint _glowPaint;
  final List<DustParticle> _glowers;
  late final Float32List _transforms;
  late final Float32List _rects;
  late final Int32List _colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double t = stopwatch.elapsedMilliseconds / 1000.0;
    var glow = 0;

    for (final p in particles) {
      // 1. Upward drift with wrap-around
      double y = (p.y0 - (t * p.speedY)) % 1.0;
      if (y < 0) y += 1.0;

      // 2. Horizontal sway
      double x =
          (p.x0 + math.sin(t * p.wobbleFreq + p.phase) * p.wobbleAmp) % 1.0;
      if (x < 0) x += 1.0;

      final double px = x * size.width;
      final double py = y * size.height;

      // 3. Twinkle alpha
      final double twinkle = 0.5 + 0.5 * math.sin(t * p.twinkleFreq + p.phase);
      final double currentAlpha =
          (p.baseOpacity * (0.4 + 0.6 * twinkle)).clamp(0.0, 1.0);

      // 4. The halo: a blurred disc is just a soft radial falloff, drawn from
      // the shared sprite (extent = disc radius + 3 sigma = 10.9 particle
      // radii) and tinted with the particle's colour at its peak alpha (see
      // [_glowPeakFactor]). All the halos go out in one draw call below.
      if (p.hasGlow) {
        final double scale = p.radius * 10.9 * 2 / _haloSide;
        final i = glow * 4;
        _transforms[i] = scale; // scos
        _transforms[i + 1] = 0; // ssin
        _transforms[i + 2] = px - _haloSide / 2 * scale;
        _transforms[i + 3] = py - _haloSide / 2 * scale;
        _colors[glow] = p.color
            .withValues(alpha: currentAlpha * _glowPeakFactor)
            .toARGB32();
        glow++;
      }

      // 5. Draw core dot
      _corePaint.color = p.color.withValues(alpha: currentAlpha);
      canvas.drawCircle(Offset(px, py), p.radius, _corePaint);
    }

    if (glow > 0) {
      canvas.drawRawAtlas(
        _halo(),
        _transforms,
        _rects,
        _colors,
        BlendMode.modulate,
        null,
        _glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HolyDustPainter oldDelegate) => false;
}

class HolyDustBackground extends StatefulWidget {
  const HolyDustBackground({
    super.key,
    this.child,
    this.particleCount = 55,
    this.palette = const [
      Colors.white,
      Color(0xFFE2F5FF),
      Color(0xFF6FE3FF),
      Color.fromARGB(255, 255, 204, 103),
    ],
  });

  final Widget? child;
  final int particleCount;
  final List<Color> palette;

  @override
  State<HolyDustBackground> createState() => _HolyDustBackgroundState();
}

/// How often the dust moves. It drifts a few percent of the card's height per
/// second and twinkles a few times a second, so thirty updates look the same as
/// sixty or two hundred and forty, and the card is not asked for a frame on
/// every refresh of the display just to move it. Frames that a tap (or anything
/// else) asks for are drawn at the display's full rate regardless.
const Duration _dustStep = Duration(milliseconds: 33);

class _HolyDustBackgroundState extends State<HolyDustBackground> {
  late final Stopwatch _stopwatch;
  late final List<DustParticle> _particles;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rand = math.Random();
    _stopwatch = Stopwatch()..start();

    // Generate fixed particle properties once
    _particles = List.generate(
      widget.particleCount,
      (_) => DustParticle.random(rand, widget.palette),
    );

    _timer = Timer.periodic(_dustStep, (_) => _frame.value++);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: HolyDustPainter(
          animation: _frame,
          particles: _particles,
          stopwatch: _stopwatch,
        ),
        child: widget.child ?? const SizedBox.expand(),
      ),
    );
  }
}
