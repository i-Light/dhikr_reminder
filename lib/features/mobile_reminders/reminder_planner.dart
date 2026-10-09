import 'dart:math';

import 'package:dhikr_reminder/features/library/domain/dhikr_display.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter/foundation.dart';

/// One notification to be delivered at [at], carrying [entry].
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.entry,
    this.transliteration,
    this.hideArabic = false,
  });

  /// Unique within one plan; the plan always replaces the previous one whole.
  final int id;
  final DateTime at;
  final DhikrEntry entry;

  /// The transliteration the card shows under the Arabic, or null for none.
  /// Settled when the plan is made, because the native card has to show it with
  /// the app closed.
  final String? transliteration;

  /// Whether the card leaves the Arabic out and shows the transliteration
  /// alone. Only ever true when there is a [transliteration] to show.
  final bool hideArabic;

  /// What the native overlay needs to show this reminder with the app closed.
  Map<String, Object> toOverlayMap() => {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'dhikrId': entry.id,
        'text': entry.name,
        'amount': entry.amount,
        'goal': entry.dailyGoal,
        'translit': transliteration ?? '',
        'hideArabic': hideArabic,
      };
}

/// How many upcoming reminders to hand the OS: a day's worth at the chosen
/// interval, but never fewer than 8 nor more than 64 (iOS-style caps are not a
/// concern on Android, but a long list is pointless — the plan is rebuilt every
/// time the app opens or settings change).
int reminderPlanLength(Duration interval) {
  final minutes = max(1, interval.inMinutes);
  return (24 * 60 ~/ minutes).clamp(8, 64);
}

/// Decides, ahead of time, which dhikr each upcoming reminder will carry.
///
/// A phone cannot run a timer while the app is closed, so unlike Windows the
/// reminders are chosen now and scheduled with the OS. Picks use the same
/// weighting as the desktop scheduler ([DhikrReminderScheduler.pickReminder]).
/// Reminders that would land before [pausedUntil] are left out.
List<PlannedReminder> planReminders({
  required DateTime now,
  required Duration interval,
  required List<DhikrEntry> entries,
  required bool useChance,
  required Random random,
  DateTime? pausedUntil,
  int? count,
  bool showTransliteration = false,
  bool showArabic = true,
}) {
  final total = count ?? reminderPlanLength(interval);
  final plan = <PlannedReminder>[];
  for (var step = 1; step <= total; step++) {
    final at = now.add(interval * step);
    if (pausedUntil != null && at.isBefore(pausedUntil)) continue;
    final entry = DhikrReminderScheduler.pickReminder(
      entries,
      random,
      useChance: useChance,
    );
    if (entry == null) return const [];
    final display = resolveDhikrDisplay(
      arabic: entry.name,
      transliteration: entry.transliteration,
      showTransliteration: showTransliteration,
      showArabic: showArabic,
    );
    plan.add(PlannedReminder(
      id: step,
      at: at,
      entry: entry,
      transliteration: display.transliteration,
      hideArabic: !display.hasArabic,
    ));
  }
  return plan;
}
