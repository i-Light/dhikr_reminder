import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The start-up splash: a small card in the reminder's own gold that fades in,
/// holds for a moment and fades out, over a transparent window — so it floats
/// on the desktop like the reminder does instead of opening an app window.
///
/// Its whole life is [kSplashDuration]; `AppShellNotifier` moves on when that
/// has elapsed, so this only has to look finished by then.
class SplashSurface extends StatefulWidget {
  const SplashSurface({super.key});

  @override
  State<SplashSurface> createState() => _SplashSurfaceState();
}

class _SplashSurfaceState extends State<SplashSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kSplashDuration,
  )..forward();

  /// In over the first ~15%, out over the last ~20%.
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 20,
    ),
  ]).animate(_controller);

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.94, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 25,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = DhikrPalette.forState(isComplete: false);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            // Opaque underneath: the card gradient is translucent, and
            // nothing but the desktop is behind it in a window this size.
            color: const Color(0xFF1B140B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: palette.accent, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: palette.cardFill),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 14,
                  children: [
                    Icon(Icons.dark_mode, color: palette.accent, size: 48),
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFF6E7C8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
