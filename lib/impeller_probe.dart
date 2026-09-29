// Temporary diagnostic entry point for the Impeller
// "Contents::SetInheritedOpacity should never be called when
// Contents::CanAcceptOpacity returns false" validation spam.
//
// It walks a list of candidate paint patterns (each wrapped in an opacity
// layer, which is what `Opacity` / `FadeTransition` / `AnimatedOpacity`
// compile down to) one phase at a time, printing a `PROBE: <index> <name>`
// marker to stdout when a phase starts. Any Impeller validation error that
// appears between two markers belongs to the phase that just started.
//
// Run with:  flutter run -d windows -t lib/impeller_probe.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/toast/dust_particles_overlay.dart';

const List<String> _phases = <String>[
  'baseline-text-no-opacity',
  'opacity-0.5 + Text',
  'opacity-0.5 + CustomPaint solid circles',
  'opacity-0.5 + CustomPaint MaskFilter.blur circles',
  'opacity-0.5 + LinearGradient DecoratedBox',
  'opacity-0.5 + BoxShadow(outer blur) container',
  'opacity-0.5 + ShaderMask(srcIn) + Text',
  'opacity-0.5 + SvgPicture.asset',
  'opacity-0.5 + SvgPicture + ColorFilter.mode',
  'opacity-1.0 + CustomPaint MaskFilter.blur circles',
  'opacity-0.45 + TextField(outline border)',
  'opacity-0.5 + radial gradient shader paint',
  'fade-transition-0.3..0.7 + BoxShadow(outer blur)',
  'no-opacity + BoxShadow(outer blur)',
  'opacity-0.5 + RepaintBoundary(blur circles)',
  'opacity-1.0 + RepaintBoundary(blur circles)',
  'animated-opacity-1.0 + blur circles (no repaint boundary)',
  'animated-opacity-1.0 + RepaintBoundary(blur circles)',
  'animated-opacity-1.0 + tint + HolyDustBackground (app combo)',
  'opacity-1.0 + tint + HolyDustBackground (plain Opacity)',
  'no-opacity + tint + HolyDustBackground (fix candidate)',
  'opacity-0.4 + Positioned.fill BoxShadow(outer blur 60) [app glow 1b]',
  'opacity-0.5 + Stack[card + BlendMode.overlay glow]',
  'opacity-1.0 + Stack[card + BlendMode.overlay glow]',
  'opacity-0.5 + Stack[card + BlendMode.plus glow] [control]',
  'opacity-0.4 + Stack[dust + BlendMode.overlay glow] [both together]',
  'opacity-0.4 + shadow-only container with TWO shadows [entity control]',
  'no-opacity + folded-alpha glow (fixed 1b) [regression]',
];

const Duration _phaseLength = Duration(milliseconds: 1800);

void main() {
  debugPrint('PROBE-BEGIN');
  runApp(const ProbeApp());
}

class ProbeApp extends StatefulWidget {
  const ProbeApp({super.key});

  @override
  State<ProbeApp> createState() => _ProbeAppState();
}

class _ProbeAppState extends State<ProbeApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  final Stopwatch _clock = Stopwatch()..start();
  final Set<int> _announced = <int>{};

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impeller probe',
      theme:
          ThemeData(useMaterial3: true, scaffoldBackgroundColor: Colors.black),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: _ticker,
          builder: (context, _) {
            final elapsed = _clock.elapsed;
            final index = elapsed.inMilliseconds ~/ _phaseLength.inMilliseconds;
            if (index >= _phases.length) {
              debugPrint('PROBE-END');
              Future<void>.delayed(
                  const Duration(milliseconds: 400), () => exit(0));
              return const Center(child: Text('probe finished'));
            }
            if (_announced.add(index)) {
              debugPrint('PROBE: $index ${_phases[index]}');
            }
            return Center(
              child: SizedBox(
                width: 520,
                height: 320,
                child: _ProbeCase(index: index, t: _ticker.value),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One candidate pattern per phase; [t] (0..1, looping) keeps every phase
/// repainting every frame, so a per-frame validation error cannot hide.
class _ProbeCase extends StatelessWidget {
  const _ProbeCase({required this.index, required this.t});

  final int index;
  final double t;

  static final math.Random _rand = math.Random(7);
  static final List<Offset> _seeds = List<Offset>.generate(
    14,
    (_) => Offset(_rand.nextDouble(), _rand.nextDouble()),
  );

  Widget _circles({required bool blur, bool radial = false}) {
    return CustomPaint(
      painter: _CirclePainter(
        seeds: _seeds,
        t: t,
        blur: blur,
        radial: radial,
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _boxShadow() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1408),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0xFFFFC857),
            blurStyle: BlurStyle.outer,
            blurRadius: 60,
          ),
        ],
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _svg({required bool colorize}) {
    return SvgPicture.asset(
      'assets/images/mandala_background.svg',
      colorFilter: colorize
          ? ColorFilter.mode(
              const Color(0xFFE9C758).withValues(alpha: 0.35),
              BlendMode.srcIn,
            )
          : null,
      fit: BoxFit.contain,
    );
  }

  Widget _gradientBox() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFE9C758), Color(0xFF6B4B12)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phase 12 pulses the opacity the way the reminder card's glow layer does;
    // everything else (except the two "no opacity" controls) sits under a flat
    // 0.5 layer. Phase 9 checks whether a *full* opacity layer also trips it.
    final double opacity = switch (index) {
      9 => 1.0,
      21 || 25 || 26 => 0.4,
      12 => 0.3 + 0.4 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)),
      _ => 0.5,
    };

    final Widget caseWidget = switch (index) {
      0 => const Text('baseline',
          style: TextStyle(fontSize: 48, color: Colors.white)),
      1 => const Text('plain text',
          style: TextStyle(fontSize: 48, color: Colors.white)),
      2 => _circles(blur: false),
      3 => _circles(blur: true),
      4 => _gradientBox(),
      5 => _boxShadow(),
      6 => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => const LinearGradient(
            colors: <Color>[Color(0xFFFFF1B8), Color(0xFFB4801F)],
          ).createShader(bounds),
          child: const Text('gradient',
              style: TextStyle(fontSize: 48, color: Colors.white)),
        ),
      7 => _svg(colorize: false),
      8 => _svg(colorize: true),
      9 => _circles(blur: true),
      10 => const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'typed text',
            ),
          ),
        ),
      11 => _circles(blur: false, radial: true),
      12 => _boxShadow(),
      13 => _boxShadow(),
      14 => RepaintBoundary(child: _circles(blur: true)),
      15 => RepaintBoundary(child: _circles(blur: true)),
      16 => _circles(blur: true),
      17 => RepaintBoundary(child: _circles(blur: true)),
      18 => _dustCombo(),
      19 => _dustCombo(),
      20 => _dustCombo(),
      // 21: the reminder card's glow layer 1b verbatim (a Positioned.fill
      // outer-blur BoxShadow container) under a 0.4 opacity layer — the exact
      // at-rest state of `FadeTransition(opacity: _glowOpacity)`.
      21 => _appGlow1b(),
      // Same layer with a second shadow: if only a *single* entity under the
      // opacity layer can take the implicit `SetInheritedOpacity` path, an
      // extra sibling entity should route it through a saveLayer instead.
      26 => _appGlow1b(shadows: 2),
      // The fix: no opacity layer at all, the 0.4 resting strength folded into
      // the shadow colour. Must stay clean.
      27 => _appGlow1b(alphaFolded: true),
      22 => _glowCase(blend: BlendMode.overlay),
      23 => _glowCase(blend: BlendMode.overlay),
      24 => _glowCase(blend: BlendMode.plus),
      25 => _glowCase(blend: BlendMode.overlay, dust: true),
      _ => const SizedBox.shrink(),
    };

    // Which opacity wrapper the phase runs under. `AnimatedOpacity` at rest is
    // *not* the same thing as `Opacity`: `RenderAnimatedOpacityMixin` always
    // publishes an `OpacityLayer` whenever alpha > 0 — including a perfectly
    // idle alpha == 255 — whereas `RenderOpacity` documents 1.0 as a fast path.
    return switch (index) {
      0 || 13 || 20 || 27 => caseWidget, // control: no opacity layer at all
      16 || 17 => AnimatedOpacity(
          duration: const Duration(milliseconds: 1),
          opacity: 1.0,
          child: caseWidget,
        ),
      15 || 19 || 23 => Opacity(opacity: 1.0, child: caseWidget),
      _ => Opacity(opacity: opacity, child: caseWidget),
    };
  }

  /// The reminder card's full-screen scrim exactly as
  /// `dhikr_reminder_overlay.dart` mounts it: a translucent tint container
  /// around the `.repeat()`ing [HolyDustBackground] (whose own build wraps the
  /// `CustomPaint` in a `RepaintBoundary`).
  Widget _dustCombo() {
    return Container(
      color: const Color(0xCC121A2E),
      child: const HolyDustBackground(particleCount: 15),
    );
  }

  /// `dhikr_reminder_overlay.dart` layer "1b": a `Positioned.fill` container
  /// whose only decoration is one `BlurStyle.outer` `BoxShadow` at
  /// `blurRadius: 60`, wrapped by `FadeTransition(opacity: _glowOpacity)` —
  /// which rests at 0.4, i.e. a permanent sub-1 opacity layer above a blurred
  /// shadow.
  Widget _appGlow1b({int shadows = 1, bool alphaFolded = false}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              boxShadow: <BoxShadow>[
                for (var i = 0; i < shadows; i++)
                  BoxShadow(
                    color: alphaFolded
                        ? const Color(0xFFFFC857).withValues(alpha: 0.4)
                        : const Color(0xFFFFC857),
                    blurStyle: BlurStyle.outer,
                    blurRadius: 60.0 + 10 * i,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// `MouseGlow`'s shape: a full-bleed `CustomPaint` with a backdrop-reading
  /// blend mode stacked above a card (or above the dust field).
  Widget _glowCase({required BlendMode blend, bool dust = false}) {
    return Stack(
      children: [
        dust
            ? const HolyDustBackground(particleCount: 15)
            : Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF2A1F0C), Color(0xFF120D05)],
                  ),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: const Color(0xFFFFC857), width: 2),
                ),
                child: const Center(
                  child: Text('card',
                      style: TextStyle(fontSize: 40, color: Colors.white)),
                ),
              ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GlowProbePainter(t: t, blend: blend),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

/// The mouse-follow glow, driven by [t] instead of a pointer so it repaints
/// every frame on its own.
class _GlowProbePainter extends CustomPainter {
  _GlowProbePainter({required this.t, required this.blend}) {
    _paint.blendMode = blend;
  }

  final double t;
  final BlendMode blend;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(
      (0.15 + 0.7 * t) * size.width,
      (0.5 + 0.25 * math.sin(t * 2 * math.pi)) * size.height,
    );
    _paint.shader = ui.Gradient.radial(
      center,
      250,
      <Color>[
        const Color.fromARGB(72, 246, 176, 90),
        const Color.fromARGB(30, 246, 176, 90),
        const Color.fromARGB(0, 246, 176, 90),
      ],
      const <double>[0, 0.6, 1],
    );
    canvas.drawCircle(center, 250, _paint);
  }

  @override
  bool shouldRepaint(covariant _GlowProbePainter oldDelegate) => true;
}

/// Solid / blurred / radial-gradient dots that drift with [t] so the phase
/// repaints on every frame.
class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.seeds,
    required this.t,
    required this.blur,
    required this.radial,
  });

  final List<Offset> seeds;
  final double t;
  final bool blur;
  final bool radial;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < seeds.length; i++) {
      final Offset seed = seeds[i];
      final double dx = seed.dx * size.width;
      final double dy = ((seed.dy + t * 0.2) % 1.0) * size.height;
      final double radius = 4.0 + i.toDouble();
      if (radial) {
        paint.maskFilter = null;
        paint.shader = ui.Gradient.radial(
          Offset(dx, dy),
          radius * 6,
          <Color>[
            const Color(0xFFFFB05A).withValues(alpha: 0.6),
            const Color(0xFFFFB05A).withValues(alpha: 0.0),
          ],
        );
        canvas.drawCircle(Offset(dx, dy), radius * 3, paint);
        continue;
      }
      paint.shader = null;
      paint.color = const Color(0xFFFFD98A).withValues(alpha: 0.8);
      paint.maskFilter =
          blur ? MaskFilter.blur(BlurStyle.normal, radius * 2.2) : null;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) => true;
}
