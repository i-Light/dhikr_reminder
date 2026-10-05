import 'dart:async';

import 'package:dhikr_reminder/core/date/hijri_date.dart';
import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/core/window/app_logo.dart';
import 'package:dhikr_reminder/core/window/tray_menu_panel.dart'
    show formatCountdown;
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/update_card.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:dhikr_reminder/platform/autostart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The home page: today's Hijri date, how much has been counted, when the next
/// reminder comes, and the app-level switches (language, start with Windows,
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
    final stats = ref.watch(dhikrStatsProvider);
    // The day counter covers the dhikr that have a daily goal, and exists
    // only if at least one does.
    final withGoal = ref
        .watch(dhikrSettingsProvider.select((s) => s.entries))
        .where((e) => e.dailyGoal > 0)
        .toList();
    final goal = withGoal.fold(0, (sum, e) => sum + e.dailyGoal);
    final doneToday = withGoal.fold(0, (sum, e) => sum + stats.todayFor(e.id));
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
                const HijriDateCard(),
                const SizedBox(height: 12),
                Row(
                  spacing: 12,
                  children: [
                    // The day counter exists only while a daily goal is set.
                    if (goal > 0)
                      Expanded(
                        child: _StatTile(
                          icon: Icons.today,
                          label: l10n.homeCountedToday,
                          value: doneToday,
                          goal: goal,
                        ),
                      ),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.bolt,
                        label: l10n.homeCountedSession,
                        value: stats.session,
                        onReset: stats.session > 0
                            ? ref.read(dhikrStatsProvider.notifier).resetSession
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _NextReminderCard(),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.goal,
    this.onReset,
  });

  final IconData icon;
  final String label;
  final int value;

  /// When set, shows "value / goal" with a progress bar underneath.
  final int? goal;

  /// When set, the tile offers to start its count over.
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (onReset != null)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      tooltip: AppLocalizations.of(context).homeResetSession,
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal == null ? '$value' : '$value / $goal',
              style: theme.textTheme.headlineMedium,
            ),
            if (goal != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (value / goal!).clamp(0.0, 1.0),
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The test button. On a phone with "display over other apps" allowed it shows
/// the same floating card a real reminder does; otherwise the in-app one.
Future<void> _showTestReminder(BuildContext context, WidgetRef ref) async {
  final reminders = ref.read(activeDhikrReminderProvider.notifier);
  final entry = reminders.testEntry();
  if (entry == null) return;
  if (ref.read(appPlatformProvider).usesNotifications) {
    final l10n = AppLocalizations.of(context);
    final shown = await ref.read(reminderOverlayProvider).showNow(
          dhikrId: entry.id,
          text: entry.name,
          amount: entry.amount,
          title: l10n.dhikrReminderTitle,
          closeLabel: l10n.commonClose,
          tip: l10n.dhikrReminderTouchEverywhereTip,
        );
    if (shown) return;
  }
  reminders.show(entry);
}

/// The countdown to the next reminder, a pause/resume control and the button
/// that shows a reminder right now.
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                                TimeOfDay.fromDateTime(pausedUntil)
                                    .format(context),
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
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: pausedUntil == null
                      ? () => pause.pauseFor(const Duration(hours: 1))
                      : pause.resume,
                  icon: Icon(
                    pausedUntil == null ? Icons.pause : Icons.play_arrow,
                  ),
                  label: Text(
                    pausedUntil == null ? l10n.trayPause : l10n.trayResume,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showTestReminder(context, ref),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.commonTestReminder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
