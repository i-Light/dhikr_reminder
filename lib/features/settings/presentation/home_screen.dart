import 'dart:async';

import 'package:dhikr_reminder/core/date/hijri_date.dart';
import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/core/window/app_logo.dart';
import 'package:dhikr_reminder/core/window/tray_menu_panel.dart'
    show formatCountdown;
import 'package:dhikr_reminder/features/mobile_reminders/setup_requirement_cards.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/bug_report_card.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/update_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:dhikr_reminder/platform/autostart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The home page: today's Hijri date, when the next reminder comes, the way to
/// report a problem, and the app-level switches (language, start with Windows,
/// updates). The dhikr list and the schedule live on the Notifications page.
///
/// One of [MainShell]'s pages and the one the window opens on. Returns its
/// content directly rather than a [Scaffold]: the [Scaffold] and the bottom
/// bar belong to [MainShell].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEnglish = ref.watch(localeProvider).languageCode == 'en';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    const AppLogo(size: 44),
                    Expanded(
                      child: Text(
                        l10n.appTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    // Labelled with the language it switches *to*, in that
                    // language, so it is findable whichever one is showing.
                    OutlinedButton.icon(
                      onPressed: ref.read(localeProvider.notifier).toggle,
                      icon: const Icon(Icons.language),
                      label: Text(isEnglish ? 'العربية' : 'English'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homeSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                // Red cards for what the reminders need and has not been
                // allowed (phones only; nothing when all is allowed).
                const SetupRequirementCards(),
                const HijriDateCard(),
                const SizedBox(height: 12),
                const _NextReminderCard(),
                // Near the top, where it is found, rather than at the bottom
                // of everything.
                const SizedBox(height: 12),
                const BugReportCard(),
                if (ref.watch(appPlatformProvider).canAutostart) ...[
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: SwitchListTile(
                      secondary: const Icon(Icons.power_settings_new),
                      title: Text(l10n.settingsAutostartTitle),
                      subtitle: Text(l10n.settingsAutostartSubtitle),
                      value: ref.watch(autostartProvider).value ?? false,
                      onChanged: ref.read(autostartProvider.notifier).set,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const UpdateCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's date in the Hijri calendar, from the device's own clock. Re-checks
/// once a minute so it turns over at midnight without a restart.
class HijriDateCard extends StatefulWidget {
  const HijriDateCard({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  State<HijriDateCard> createState() => _HijriDateCardState();
}

class _HijriDateCardState extends State<HijriDateCard> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
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
    final theme = Theme.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            Icon(
              Icons.calendar_month,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            Expanded(
              child: Text(
                formatHijriDate(widget.clock(), arabic: arabic),
                key: const ValueKey('hijri-date'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The countdown to the next reminder, with the pause/resume control on the same
/// line. The button that shows a reminder right now lives with the other
/// reminder settings on the Notifications page.
class _NextReminderCard extends ConsumerStatefulWidget {
  const _NextReminderCard();

  @override
  ConsumerState<_NextReminderCard> createState() => _NextReminderCardState();
}

class _NextReminderCardState extends ConsumerState<_NextReminderCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nextAt = ref.watch(dhikrReminderSchedulerProvider);
    final pausedUntil = ref.watch(reminderPauseProvider);
    final remaining = nextAt?.difference(DateTime.now());
    final pause = ref.read(reminderPauseProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 12,
          children: [
            Icon(
              pausedUntil == null
                  ? Icons.timer_outlined
                  : Icons.pause_circle_outline,
              color: theme.colorScheme.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeNextReminder,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    pausedUntil != null
                        ? l10n.trayPausedUntil(
                            TimeOfDay.fromDateTime(pausedUntil).format(context),
                          )
                        : remaining == null
                            ? l10n.trayNextDhikrPending
                            : formatCountdown(remaining),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('pause-button'),
              onPressed: pausedUntil == null
                  ? () => pause.pauseFor(const Duration(hours: 1))
                  : pause.resume,
              icon: Icon(pausedUntil == null ? Icons.pause : Icons.play_arrow),
              label: Text(
                pausedUntil == null
                    ? l10n.homePauseShort
                    : l10n.homeResumeShort,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
