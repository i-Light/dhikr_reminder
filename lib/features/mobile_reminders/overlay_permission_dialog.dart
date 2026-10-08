import 'dart:ui' show lerpDouble;

import 'package:dhikr_reminder/core/window/app_logo.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's name as the phone's settings list shows it: the label in the
/// Android manifest, which is Arabic whatever language the app is showing.
const _systemAppLabel = 'ذِكر';

/// Explains the "show over other apps" permission, with a picture of the
/// system screen the person is about to be sent to, and asks if they want to
/// go there. True if they chose Allow.
///
/// Nothing is opened here; the caller does that, so a "Not now" costs nothing.
Future<bool> showOverlayPermissionDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final allow = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.layers_outlined),
      title: Text(l10n.overlayPromptTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.overlayPromptBody),
          const SizedBox(height: 16),
          const OverlaySettingsPreview(),
          const SizedBox(height: 12),
          Text(
            l10n.overlayPreviewHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.overlayPromptLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.commonAllow),
        ),
      ],
    ),
  );
  return allow ?? false;
}

/// The whole "allow showing over other apps" step: the preview dialog, then,
/// if they agreed, the system screen. Used by the start-up prompt and by the
/// red card, so both look and behave the same. True if the system screen was
/// opened.
Future<bool> askForOverlayPermission(
    BuildContext context, WidgetRef ref) async {
  final wantsIt = await showOverlayPermissionDialog(context);
  if (wantsIt) await ref.read(overlayAllowedProvider.notifier).request();
  return wantsIt;
}

/// A drawing of the system's "Display over other apps" page for this app: its
/// icon and name, and the switch the person has to turn on. The switch plays
/// itself on once when this appears (a tap on the picture plays it again), so
/// the person knows what to look for before leaving the app.
///
/// It is a picture, not the real thing: the page differs from phone to phone,
/// so only what is the same everywhere is drawn.
class OverlaySettingsPreview extends StatefulWidget {
  const OverlaySettingsPreview({super.key});

  @override
  State<OverlaySettingsPreview> createState() => _OverlaySettingsPreviewState();
}

class _OverlaySettingsPreviewState extends State<OverlaySettingsPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0 to 1 while [t] is between [begin] and [end].
  static double _phase(double t, double begin, double end) =>
      Curves.easeInOut.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: l10n.overlayPreviewHint,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _controller.forward(from: 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    spacing: 12,
                    children: [
                      const Icon(Icons.arrow_back, size: 20),
                      Expanded(
                        child: Text(
                          l10n.overlayPreviewScreenTitle,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // The list as phones show it: other apps above and below, and
                // this one, with its switch, in the middle.
                const _OtherAppRow(widths: (84, 48)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      spacing: 12,
                      children: [
                        const _AppIconTile(
                          child: AppLogo(size: 32),
                        ),
                        Expanded(
                          child: Text(
                            _systemAppLabel,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => _FakeSwitch(
                            on: _phase(_controller.value, 0.40, 0.58),
                            ring: _ring(_controller.value),
                            finger: _finger(_controller.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const _OtherAppRow(widths: (64, 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The highlight around the switch: it fades in, then out once it is on.
  static double _ring(double t) {
    if (t < 0.1) return 0;
    if (t < 0.3) return _phase(t, 0.1, 0.3);
    if (t < 0.75) return 1;
    return 1 - _phase(t, 0.75, 0.95);
  }

  /// The finger: it appears, presses at the moment the switch turns on, and
  /// goes away.
  static double _finger(double t) {
    if (t < 0.2) return _phase(t, 0.1, 0.2);
    if (t < 0.7) return 1;
    return 1 - _phase(t, 0.7, 0.85);
  }
}

/// The launcher icon on its dark tile, as the settings list shows it.
class _AppIconTile extends StatelessWidget {
  const _AppIconTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B140B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// A faded stand-in for some other app in the list: a grey icon, two grey bars
/// ([widths]: the name's and the size's) and a switch that stays off.
class _OtherAppRow extends StatelessWidget {
  const _OtherAppRow({required this.widths});

  final (double, double) widths;

  @override
  Widget build(BuildContext context) {
    final grey =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    Widget bar(double width) => Container(
          width: width,
          height: 10,
          decoration: BoxDecoration(
            color: grey,
            borderRadius: BorderRadius.circular(5),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        spacing: 12,
        children: [
          _AppIconTile(
            child: DecoratedBox(
              decoration: BoxDecoration(color: grey, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [bar(widths.$1), bar(widths.$2)],
            ),
          ),
          const Opacity(
            opacity: 0.45,
            child: _FakeSwitch(on: 0, ring: 0, finger: 0),
          ),
        ],
      ),
    );
  }
}

/// A Material-style switch drawn by hand, with [on] from 0 (off) to 1 (on),
/// a highlight ring and a pressing finger. Not interactive.
class _FakeSwitch extends StatelessWidget {
  const _FakeSwitch({
    required this.on,
    required this.ring,
    required this.finger,
  });

  final double on;
  final double ring;
  final double finger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track =
        Color.lerp(scheme.surfaceContainerHighest, scheme.primary, on)!;
    final edge = Color.lerp(scheme.outline, scheme.primary, on)!;
    final knob = Color.lerp(scheme.outline, scheme.onPrimary, on)!;

    return SizedBox(
      width: 64,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.primary.withValues(alpha: ring),
                width: 3,
              ),
            ),
          ),
          Container(
            width: 52,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: edge, width: 2),
            ),
            child: Align(
              alignment: AlignmentDirectional(lerpDouble(-1, 1, on)!, 0),
              child: Container(
                width: lerpDouble(14, 22, on),
                height: lerpDouble(14, 22, on),
                decoration: BoxDecoration(color: knob, shape: BoxShape.circle),
              ),
            ),
          ),
          PositionedDirectional(
            end: 2,
            top: 22 + 6 * (1 - finger),
            child: Opacity(
              opacity: finger,
              child: Icon(Icons.touch_app, size: 30, color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
