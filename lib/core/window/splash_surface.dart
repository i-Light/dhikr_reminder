import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/core/window/svg_icon.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The start-up splash: a small solid card — the app's logo, its name, a line
/// about what it does and the running version — that fades in, holds for a
/// moment and fades out, so it floats on the desktop like the reminder does
/// instead of opening an app window.
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
  static const _background = Color(0xFF1B140B);
  static const _accent = Color(0xFFE7AA48);
  static const _text = Color(0xFFF6E7C8);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kSplashDuration,
  )..forward();

  /// In over the first ~15%, out over the last ~20%.
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween:
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
    TweenSequenceItem(
      tween:
          Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 20,
    ),
  ]).animate(_controller);

  /// The logo, with any `<use>`d images inlined — flutter_svg skips those, the
  /// same way it does when drawing the tray icon (see [inlineUsedImages]).
  late final Future<String> _logo =
      rootBundle.loadString(kAppIconSvgAsset).then(inlineUsedImages);

  late final Future<String> _version = PackageInfo.fromPlatform()
      .then((info) => info.version)
      .catchError((_) => '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: _background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _accent, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: FutureBuilder<String>(
                    future: _logo,
                    builder: (context, snapshot) => snapshot.hasData
                        ? SvgPicture.string(snapshot.data!)
                        : const SizedBox.shrink(),
                  ),
                ),
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.splashDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _text.withValues(alpha: 0.75),
                  ),
                ),
                FutureBuilder<String>(
                  future: _version,
                  builder: (context, snapshot) {
                    final version = snapshot.data ?? '';
                    return Text(
                      version.isEmpty ? '' : 'v$version',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _accent,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
