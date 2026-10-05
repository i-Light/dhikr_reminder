import 'dart:async';

import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flat dark fill of the menu: one solid color, no gradient.
const _menuBackground = Color(0xFF1B140B);

/// The tray icon's right-click menu, drawn in the reminder card's own gold —
/// the same palette and border language — rather than the native Windows menu.
///
/// Shown while [AppShellNotifier] has the window turned into a small popup
/// (see [ShellMode.trayMenu]); it fills that window
/// edge to edge, which is why it draws its own border.
///
/// Every row is an icon and a label. A row that toggles something (the sound)
/// shows its state by swapping the icon itself, not with a checkbox.
class TrayMenuPanel extends ConsumerWidget {
  const TrayMenuPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = DhikrPalette.forState(isComplete: false);
    final shell = ref.read(appShellProvider.notifier);
    final isMuted = ref.watch(dhikrSettingsProvider.select((s) => s.isMuted));

    // The window is transparent and a few pixels bigger than the card, so the
    // card's rounded corners show the desktop behind them.
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: _menuBackground,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.accent, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _TrayMenuItem(
                accent: palette.accent,
                icon: Icons.open_in_new_rounded,
                label: l10n.trayOpenApp,
                onTap: shell.openApp,
              ),
              _NextDhikrItem(accent: palette.accent),
              _TrayMenuItem(
                accent: palette.accent,
                // The icon is the state: speaker while sound is on, crossed
                // out while it is muted.
                icon: isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                label: isMuted ? l10n.traySoundOff : l10n.traySoundOn,
                onTap: shell.toggleMuted,
              ),
              Divider(
                height: 9,
                indent: 12,
                endIndent: 12,
                color: palette.accent.withValues(alpha: 0.35),
              ),
              _TrayMenuItem(
                accent: palette.accent,
                icon: Icons.power_settings_new_rounded,
                label: l10n.trayQuit,
                onTap: shell.quit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable row: [icon] then [label]. Passing a [subtitle] adds a second,
/// quieter line under the label.
class _TrayMenuItem extends StatelessWidget {
  const _TrayMenuItem({
    required this.accent,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final Color accent;
  final IconData icon;
  final String label;
  final String? subtitle;

  /// Null makes the row informational: no hover, no press.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return SizedBox(
      height: 36,
      child: InkWell(
        onTap: onTap,
        hoverColor: accent.withValues(alpha: 0.16),
        splashColor: accent.withValues(alpha: 0.24),
        highlightColor: accent.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 10,
            children: [
              // Keyed on the icon so a change (mute <-> unmute) plays the
              // swap rather than snapping.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(icon, key: ValueKey(icon), color: accent, size: 18),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontSize: 10,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Next dhikr — in 12:34": counts down to the scheduler's next reminder, once
/// a second. Informational, so it has no tap.
class _NextDhikrItem extends ConsumerStatefulWidget {
  const _NextDhikrItem({required this.accent});

  final Color accent;

  @override
  ConsumerState<_NextDhikrItem> createState() => _NextDhikrItemState();
}

class _NextDhikrItemState extends ConsumerState<_NextDhikrItem> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nextAt = ref.watch(dhikrReminderSchedulerProvider);
    final remaining = nextAt?.difference(DateTime.now());

    return _TrayMenuItem(
      accent: widget.accent,
      icon: Icons.timer_outlined,
      label: l10n.trayNextDhikr,
      subtitle: remaining == null
          ? l10n.trayNextDhikrPending
          : l10n.trayNextDhikrIn(formatCountdown(remaining)),
    );
  }
}

/// `m:ss` under an hour, `h:mm:ss` from an hour up; never negative.
String formatCountdown(Duration remaining) {
  final total = remaining.isNegative ? 0 : remaining.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
  return '$minutes:$ss';
}
