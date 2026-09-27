import 'dart:math' as math;
import 'package:flutter/material.dart';

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

class HolyDustPainter extends CustomPainter {
  HolyDustPainter({
    required this.animation,
    required this.particles,
    required this.stopwatch,
  })  : _glowPaint = Paint()..style = PaintingStyle.fill,
        _corePaint = Paint()..style = PaintingStyle.fill,
        super(repaint: animation);

  final Animation<double> animation;
  final List<DustParticle> particles;
  final Stopwatch stopwatch;

  // Reusable paint instances (avoids creating new objects every 16ms)
  final Paint _glowPaint;
  final Paint _corePaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double t = stopwatch.elapsedMilliseconds / 1000.0;

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
      final offset = Offset(px, py);

      // 3. Twinkle alpha
      final double twinkle = 0.5 + 0.5 * math.sin(t * p.twinkleFreq + p.phase);
      final double currentAlpha =
          (p.baseOpacity * (0.4 + 0.6 * twinkle)).clamp(0.0, 1.0);

      // 4. Draw halo
      if (p.hasGlow) {
        _glowPaint
          ..color = p.color.withValues(alpha: currentAlpha * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2.8);
        canvas.drawCircle(offset, p.radius * 2.5, _glowPaint);
      }

      // 5. Draw core dot
      _corePaint.color = p.color.withValues(alpha: currentAlpha);
      canvas.drawCircle(offset, p.radius, _corePaint);
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

class _HolyDustBackgroundState extends State<HolyDustBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Stopwatch _stopwatch;
  late final List<DustParticle> _particles;

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

    // Continuous ticker driver
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: HolyDustPainter(
          animation: _controller,
          particles: _particles,
          stopwatch: _stopwatch,
        ),
        child: widget.child ?? const SizedBox.expand(),
      ),
    );
  }
}
