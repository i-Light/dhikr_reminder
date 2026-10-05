import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/notifications/presentation/dhikr_edit_dialog.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interval shortcuts, in minutes. Any other value is reachable with the
/// slider.
const notificationIntervalShortcuts = [5, 15, 30, 60, 120];

/// The Notifications page: when a dhikr reaches you and which ones.
///
/// Every change is saved the moment it is made — there is no Save button to
/// forget — and a deleted dhikr can be brought back from the snackbar.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(dhikrSettingsProvider);
    final notifier = ref.read(dhikrSettingsProvider.notifier);

    Future<void> add() async {
      final fresh = DhikrEntry(
        id: notifier.allocateId(),
        name: '',
        amount: dhikrAmountDefault,
      );
      final result = await showDhikrEditDialog(
        context,
        entry: fresh,
        isNew: true,
        showFrequency: settings.useChance,
      );
      if (result == null) return;
      final current = ref.read(dhikrSettingsProvider).entries;
      await notifier.updateEntries([...current, result]);
    }

    Future<void> edit(DhikrEntry entry) async {
      final result = await showDhikrEditDialog(
        context,
        entry: entry,
        isNew: false,
        showFrequency: settings.useChance,
      );
      if (result == null) return;
      final current = ref.read(dhikrSettingsProvider).entries;
      await notifier.updateEntries([
        for (final e in current) e.id == result.id ? result : e,
      ]);
    }

    void remove(DhikrEntry entry) {
      final current = ref.read(dhikrSettingsProvider).entries;
      final index = current.indexWhere((e) => e.id == entry.id);
      if (index < 0) return;
      notifier.updateEntries([...current]..removeAt(index));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.notifDeleted),
            action: SnackBarAction(
              label: l10n.notifUndo,
              onPressed: () {
                final now = ref.read(dhikrSettingsProvider).entries;
                notifier.updateEntries(
                  [...now]..insert(index.clamp(0, now.length), entry),
                );
              },
            ),
          ),
        );
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(l10n.notifTitle, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                l10n.notifSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // On a phone, reminders can float over other apps once allowed.
              if (ref.watch(appPlatformProvider).usesNotifications)
                const _OverlayPermissionCard(),
              _SectionLabel(l10n.notifScheduleSection),
              _ScheduleCard(settings: settings),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _SectionLabel(
                      '${l10n.notifMySection} (${settings.entries.length})',
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: settings.isLoaded ? add : null,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.notifAddDhikr),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (settings.isLoaded && settings.entries.isEmpty)
                _EmptyList(onAdd: add)
              else
                for (final entry in settings.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(entry.id),
                      background: const _SwipeBackground(
                        alignment: AlignmentDirectional.centerStart,
                      ),
                      secondaryBackground: const _SwipeBackground(
                        alignment: AlignmentDirectional.centerEnd,
                      ),
                      onDismissed: (_) => remove(entry),
                      child: _DhikrTile(
                        entry: entry,
                        showFrequency: settings.useChance,
                        onEdit: () => edit(entry),
                        onDelete: () => remove(entry),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Show over other apps": explains the permission and opens the system screen
/// where it is granted. Gone once it is granted (and while that is unknown).
class _OverlayPermissionCard extends ConsumerWidget {
  const _OverlayPermissionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allowed = ref.watch(overlayAllowedProvider).value;
    if (allowed ?? true) return const SizedBox.shrink();

    return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 12,
              children: [
                Icon(Icons.layers_outlined, color: theme.colorScheme.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.overlayTitle, style: theme.textTheme.bodyLarge),
                      Text(
                        l10n.overlaySubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: ref.read(overlayAllowedProvider.notifier).request,
                  child: Text(l10n.overlayAllow),
                ),
              ],
            ),
          ),
        ));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Interval, sound and weighting — the settings that apply to every dhikr.
class _ScheduleCard extends ConsumerStatefulWidget {
  const _ScheduleCard({required this.settings});

  final DhikrSettings settings;

  @override
  ConsumerState<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends ConsumerState<_ScheduleCard> {
  /// The slider's value while it is being dragged; the setting itself is only
  /// written when the drag ends, so the reminder timer is not restarted on
  /// every pixel.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = widget.settings;
    final notifier = ref.read(dhikrSettingsProvider.notifier);
    final minutes = _dragging ?? settings.intervalMinutes.toDouble();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.notifIntervalTitle,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        l10n.notifIntervalMinutes(minutes.round()),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: minutes,
                    min: dhikrReminderIntervalMin.toDouble(),
                    max: dhikrReminderIntervalMax.toDouble(),
                    divisions:
                        dhikrReminderIntervalMax - dhikrReminderIntervalMin,
                    onChanged: settings.isLoaded
                        ? (value) => setState(() => _dragging = value)
                        : null,
                    onChangeEnd: (value) {
                      setState(() => _dragging = null);
                      notifier.updateInterval(value.round());
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final shortcut in notificationIntervalShortcuts)
                        ChoiceChip(
                          label: Text(l10n.notifIntervalMinutes(shortcut)),
                          selected: settings.intervalMinutes == shortcut,
                          onSelected: settings.isLoaded
                              ? (_) => notifier.updateInterval(shortcut)
                              : null,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            SwitchListTile(
              secondary: Icon(
                settings.isMuted ? Icons.volume_off : Icons.volume_up,
              ),
              title: Text(l10n.notifSoundTitle),
              subtitle: Text(l10n.notifSoundSubtitle),
              value: !settings.isMuted,
              onChanged: (on) => notifier.updateMuted(!on),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.balance),
              title: Text(l10n.notifPriorityTitle),
              subtitle: Text(l10n.notifPrioritySubtitle),
              value: settings.useChance,
              onChanged: settings.isLoaded ? notifier.updateUseChance : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// One dhikr in the list: its text, how many repetitions, how often.
class _DhikrTile extends StatelessWidget {
  const _DhikrTile({
    required this.entry,
    required this.showFrequency,
    required this.onEdit,
    required this.onDelete,
  });

  final DhikrEntry entry;
  final bool showFrequency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    // A dhikr set to "never" is dimmed: it stays in the list but is skipped.
    final skipped = showFrequency && entry.chance == 0;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: skipped ? 0.45 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name.isEmpty ? '-' : entry.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'AliMeshref',
                          fontSize: 20,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                            icon: Icons.repeat,
                            label: l10n.notifRepeatCount(entry.amount),
                          ),
                          if (entry.dailyGoal > 0)
                            _InfoChip(
                              icon: Icons.flag_outlined,
                              label: l10n.notifGoalCount(entry.dailyGoal),
                            ),
                          if (showFrequency)
                            _InfoChip(
                              icon: Icons.balance,
                              label: entry.chance == 0
                                  ? l10n.notifFrequencyNever
                                  : l10n.notifFrequencyValue(entry.chance),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.commonDelete,
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: colors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onPrimaryContainer),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.alignment});

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(l10n.notifEmptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.notifEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n.notifAddDhikr),
          ),
        ],
      ),
    );
  }
}
