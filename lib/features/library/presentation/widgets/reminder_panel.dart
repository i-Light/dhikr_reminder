import 'dart:async';

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/widgets/amount_stepper.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/notifications/application/test_reminder.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The part of a library card that stays hidden until its reminder button is
/// pressed: how many times to say the dhikr and an "Add" button, or, when it
/// is already in the person's reminders, a note saying so with the same count
/// to change and a way to take it out.
class ReminderPanel extends ConsumerStatefulWidget {
  const ReminderPanel({super.key, required this.item});

  final DhikrItem item;

  @override
  ConsumerState<ReminderPanel> createState() => _ReminderPanelState();
}

class _ReminderPanelState extends ConsumerState<ReminderPanel> {
  /// The count picked before the dhikr is added. Starts at the count the
  /// sources give for it.
  late int _amount = widget.item.count.clamp(dhikrAmountMin, dhikrAmountMax);

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(dhikrSettingsProvider.notifier)
        .addFromLibrary(widget.item, amount: _amount);
    if (mounted) _say(l10n.libraryAddedSnack);
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(dhikrSettingsProvider.notifier)
        .removeLibraryItem(widget.item.id);
    if (mounted) _say(l10n.libraryRemovedSnack);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entry = ref.watch(
      dhikrSettingsProvider.select(
        (s) =>
            s.entries.where((e) => e.libraryId == widget.item.id).firstOrNull,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry != null) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.libraryAddedNote,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AmountStepper(
                value: entry.amount,
                min: dhikrAmountMin,
                max: dhikrAmountMax,
                onChanged: (value) => unawaited(
                  ref
                      .read(dhikrSettingsProvider.notifier)
                      .setLibraryItemAmount(widget.item.id, value),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => unawaited(_remove()),
                    icon: const Icon(Icons.notifications_off_outlined),
                    label: Text(l10n.libraryRemoveButton),
                    style: TextButton.styleFrom(foregroundColor: colors.error),
                  ),
                  const Spacer(),
                  // Only here, one tap deep, for a dhikr that is already in
                  // the reminders: counts it now on the same card a reminder
                  // uses, instead of a counter screen of its own.
                  if (Features.counter)
                    FilledButton.tonalIcon(
                      key: const ValueKey('count-now-button'),
                      onPressed: () =>
                          unawaited(showReminderFor(context, ref, entry)),
                      icon: const Icon(Icons.touch_app_outlined),
                      label: Text(l10n.libraryCountNow),
                    ),
                ],
              ),
            ] else ...[
              Text(l10n.libraryAddRepeatsLabel,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              AmountStepper(
                value: _amount,
                min: dhikrAmountMin,
                max: dhikrAmountMax,
                onChanged: (value) => setState(() => _amount = value),
              ),
              if (widget.item.count > 1) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.libraryRecommendedCount(widget.item.count),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: () => unawaited(_add()),
                  icon: const Icon(Icons.add_alert_outlined),
                  label: Text(l10n.libraryAddConfirm),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
