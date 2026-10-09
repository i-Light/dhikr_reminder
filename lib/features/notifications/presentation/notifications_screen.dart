import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/core/widgets/collapsible_card.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/application/transliteration_controller.dart';
import 'package:dhikr_reminder/features/mobile_reminders/setup_requirement_cards.dart';
import 'package:dhikr_reminder/features/notifications/application/test_reminder.dart';
import 'package:dhikr_reminder/features/notifications/presentation/dhikr_edit_dialog.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interval shortcuts, in minutes. Any other value is reachable with the
/// slider.
const notificationIntervalShortcuts = [5, 15, 30, 60, 120];

/// The colour of a dhikr whose daily goal has been reached: the progress bar,
/// and the tint the whole card takes on.
const _achievedGreen = Color(0xFF2FBF8A);

/// The Notifications page: when a dhikr reaches you and which ones.
///
/// Every change is saved the moment it is made, there is no Save button to
/// forget, and a deleted dhikr can be brought back from the snackbar. Dhikr are
/// not typed in here: adding one opens the library, where each entry has its
/// own "add to reminders" button.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(dhikrSettingsProvider);
    final notifier = ref.read(dhikrSettingsProvider.notifier);

    void add() {
      ref.read(dhikrLibraryProvider.notifier).setAddHint(true);
      ref.read(shellTabProvider.notifier).show(ShellTab.library);
    }

    Future<void> edit(DhikrEntry entry) async {
      final result = await showDhikrEditDialog(
        context,
        entry: entry,
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
              // On a phone, what the reminders need and has not been allowed.
              const SetupRequirementCards(),
              _ReminderSettingsCard(settings: settings),
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

/// How often a reminder comes, whether some dhikr come up more than others, and
/// the button that shows a reminder right now: the settings that apply to every
/// dhikr, folded away until wanted. Folded, it says in two short lines what is
/// set, so there is no need to open it to find out.
class _ReminderSettingsCard extends ConsumerStatefulWidget {
  const _ReminderSettingsCard({required this.settings});

  final DhikrSettings settings;

  @override
  ConsumerState<_ReminderSettingsCard> createState() =>
      _ReminderSettingsCardState();
}

class _ReminderSettingsCardState extends ConsumerState<_ReminderSettingsCard> {
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
    final showTransliteration = ref.watch(showTransliterationProvider);
    final minutes = _dragging ?? settings.intervalMinutes.toDouble();
    final muted = theme.colorScheme.onSurfaceVariant;

    return CollapsibleCard(
      key: const ValueKey('reminder-settings'),
      initiallyExpanded: false,
      leadingIcon: Icon(Icons.tune, color: theme.colorScheme.primary),
      title: l10n.notifSettingsTitle,
      // Two lines at most: how often, and how the dhikr are picked.
      collapsedSummary: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.notifIntervalTitle} '
            '${l10n.notifIntervalMinutes(settings.intervalMinutes)}',
            key: const ValueKey('settings-summary-interval'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 2),
          Text(
            settings.useChance
                ? l10n.notifSummaryWeighted
                : l10n.notifSummaryEqual,
            key: const ValueKey('settings-summary-priority'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: muted),
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
            divisions: dhikrReminderIntervalMax - dhikrReminderIntervalMin,
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
          const Divider(height: 24),
          // The sound switch is hidden until reminders have a sound worth
          // switching (planned for a later version). The setting itself
          // (DhikrSettings.isMuted, updateMuted) and the strings
          // (notifSoundTitle, notifSoundSubtitle) are still in place.
          _CompactSwitchRow(
            rowKey: const ValueKey('priority-row'),
            switchKey: const ValueKey('priority-switch'),
            title: l10n.notifPriorityTitle,
            subtitle: l10n.notifPrioritySubtitle,
            value: settings.useChance,
            onChanged: settings.isLoaded ? notifier.updateUseChance : null,
          ),
          const Divider(height: 24),
          // The same switch as the library's "Show Arabic", for the reminder
          // card. It only hides the Arabic: the transliteration itself is
          // switched on in the library settings.
          _CompactSwitchRow(
            rowKey: const ValueKey('overlay-arabic-row'),
            switchKey: const ValueKey('overlay-arabic-switch'),
            title: l10n.notifOverlayArabicTitle,
            subtitle: showTransliteration
                ? l10n.notifOverlayArabicSubtitle
                : l10n.notifOverlayArabicNeedsTransliteration,
            value: settings.overlayShowArabic || !showTransliteration,
            onChanged: settings.isLoaded && showTransliteration
                ? notifier.updateOverlayShowArabic
                : null,
          ),
          const Divider(height: 24),
          OutlinedButton.icon(
            key: const ValueKey('test-reminder-button'),
            onPressed: () => showTestReminder(context, ref),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.commonTestReminder),
          ),
        ],
      ),
    );
  }
}

/// A switch with its text beside it, packed close: no icon, a small gap, and no
/// padding around the switch beyond what it needs. The whole row toggles it.
class _CompactSwitchRow extends StatelessWidget {
  const _CompactSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.rowKey,
    this.switchKey,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Key? rowKey;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: rowKey,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              key: switchKey,
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

/// One dhikr in the list: its text, how many repetitions, how often, and, if it
/// has a daily goal, how far today has got. Once the goal is reached the whole
/// card takes on a green tint; going beyond it changes nothing but the number.
class _DhikrTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // A dhikr set to "never" is dimmed: it stays in the list but is skipped.
    final skipped = showFrequency && entry.chance == 0;

    final hasGoal = entry.dailyGoal > 0;
    final todayKey = dhikrDayKey(ref.watch(dhikrStatsClockProvider)());
    final done = hasGoal
        ? ref.watch(
            dhikrStatsProvider.select((s) => s.forToday(todayKey, entry.id)),
          )
        : 0;
    final achieved = hasGoal && done >= entry.dailyGoal;
    final base = theme.cardTheme.color ?? colors.surface;

    return Card(
      key:
          ValueKey(achieved ? 'tile-achieved-${entry.id}' : 'tile-${entry.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: achieved
          ? Color.alphaBlend(_achievedGreen.withValues(alpha: 0.32), base)
          : null,
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
                          fontFamily: 'NotoSansArabic',
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
                          if (showFrequency)
                            _InfoChip(
                              icon: Icons.balance,
                              label: entry.chance == 0
                                  ? l10n.notifFrequencyNever
                                  : l10n.notifFrequencyValue(entry.chance),
                            ),
                        ],
                      ),
                      if (hasGoal) ...[
                        const SizedBox(height: 10),
                        _GoalProgress(
                          done: done,
                          goal: entry.dailyGoal,
                          achieved: achieved,
                        ),
                      ],
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

/// The bar and the words for a daily goal: "today 42 of 100".
class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
    required this.done,
    required this.goal,
    required this.achieved,
  });

  final int done;
  final int goal;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            key: const ValueKey('goal-progress'),
            value: (done / goal).clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            color: achieved ? _achievedGreen : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        if (achieved) ...[
          const Icon(Icons.check_circle, size: 18, color: _achievedGreen),
          const SizedBox(width: 4),
        ],
        Text(
          l10n.notifGoalProgress(done, goal),
          key: const ValueKey('goal-text'),
          style: theme.textTheme.labelMedium,
        ),
      ],
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
