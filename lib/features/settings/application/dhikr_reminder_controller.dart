import 'dart:async';
import 'dart:math';

import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dhikr reminder currently on screen, plus how many times it's been
/// tapped so far — [DhikrReminderOverlay] renders this, [count] climbing
/// toward [DhikrEntry.amount] with every tap.
@immutable
class ActiveDhikrReminder {
  const ActiveDhikrReminder({required this.entry, this.count = 0});

  final DhikrEntry entry;
  final int count;

  /// Nothing to count toward (amount left at 0) reads as "no target" rather
  /// than "already complete" — the clicker just counts up freely.
  bool get hasTarget => entry.amount > 0;

  bool get isComplete => hasTarget && count >= entry.amount;

  ActiveDhikrReminder copyWith({int? count}) =>
      ActiveDhikrReminder(entry: entry, count: count ?? this.count);
}

/// Holds whichever dhikr reminder is currently floating on screen, if any.
/// `DhikrReminderScheduler` populates it on a timer; the reminder popup
/// (`DhikrReminderSurface`) renders it and drives [increment]/[dismiss] from taps.
class ActiveDhikrReminderNotifier extends Notifier<ActiveDhikrReminder?> {
  @override
  ActiveDhikrReminder? build() => null;

  void show(DhikrEntry entry) {
    state = ActiveDhikrReminder(entry: entry);
    // No sound for now: the system beep this used to play is off on purpose.
    // The mute setting (`isMuted`) stays wired up for when each dhikr gets its
    // own optional custom sound — play it here, unless muted.
  }

  /// Pops a reminder right now, for the settings page's test button and the
  /// debug-session demo.
  ///
  /// Deliberately not `DhikrReminderScheduler.pickWeighted`: that is
  /// `@visibleForTesting`, and this is app code. The point is to see the card,
  /// not to sample the weighting, so it just takes the first eligible entry.
  void showTest() {
    final settings = ref.read(dhikrSettingsProvider);
    // With the chance option off nothing is excluded, whatever chance an
    // entry has stored.
    final entries = settings.entries
        .where((entry) => !settings.useChance || entry.chance > 0)
        .toList();
    if (entries.isEmpty) return;
    show(entries.first);
  }

  void increment() {
    final current = state;
    if (current == null || current.isComplete) return;
    state = current.copyWith(count: current.count + 1);
    ref.read(dhikrStatsProvider.notifier).recordTap(current.entry.id);
  }

  void dismiss() => state = null;
}

final activeDhikrReminderProvider =
    NotifierProvider<ActiveDhikrReminderNotifier, ActiveDhikrReminder?>(
  ActiveDhikrReminderNotifier.new,
);

/// Until when reminders are paused (from the tray menu), or null when they are
/// not. In memory only: a restart is a fresh start, never a silently muted app.
class ReminderPauseNotifier extends Notifier<DateTime?> {
  Timer? _resume;

  @override
  DateTime? build() {
    ref.onDispose(() => _resume?.cancel());
    return null;
  }

  /// Pauses reminders for [duration]; they pick themselves up again after it.
  void pauseFor(Duration duration) {
    _resume?.cancel();
    state = DateTime.now().add(duration);
    _resume = Timer(duration, resume);
  }

  void resume() {
    _resume?.cancel();
    state = null;
  }
}

final reminderPauseProvider =
    NotifierProvider<ReminderPauseNotifier, DateTime?>(
  ReminderPauseNotifier.new,
);

/// Fires a dhikr reminder every [DhikrSettings.intervalMinutes] minutes,
/// picking which one with [pickReminder] — a weighted roll over
/// [DhikrEntry.chance] when [DhikrSettings.useChance] is on, a flat one when
/// it is off.
///
/// Its state is when the next reminder is due (`null` until the saved settings
/// have loaded), which is what the tray menu's countdown reads.
///
/// Stays idle until [DhikrSettings.isLoaded] — before the saved settings come
/// back from disk the only entries on hand are the seed defaults, every one of
/// them at full chance, so scheduling against them meant a restart could pop up
/// a dhikr the user had muted (chance 0) or deleted outright.
///
/// A `Notifier` rather than a plain service class so it can `ref.watch`
/// the interval and reschedule its own timer whenever it changes — the same
/// "rebuild tears down and re-sets-up its own side effect" shape
/// `NotificationCenter` uses for its per-toast timers, just at the
/// provider's own `build()` instead of per entry. Kept alive for the app's
/// lifetime by `DhikrReminderOverlay` watching it once at the root, same as
/// `ToastOverlay` keeps `NotificationCenter`'s timers alive by existing.
class DhikrReminderScheduler extends Notifier<DateTime?> {
  final _random = Random();

  @override
  DateTime? build() {
    // Watched narrowly: the timer should restart when the interval changes,
    // not every time an entry is edited in the settings card — a full rebuild
    // per keystroke would keep pushing the next reminder back indefinitely.
    final isLoaded = ref.watch(dhikrSettingsProvider.select((s) => s.isLoaded));
    if (!isLoaded) return null;
    final interval = Duration(
      minutes:
          ref.watch(dhikrSettingsProvider.select((s) => s.intervalMinutes)),
    );
    final timer = Timer.periodic(interval, (_) {
      _fire();
      state = DateTime.now().add(interval);
    });
    ref.onDispose(timer.cancel);
    return DateTime.now().add(interval);
  }

  void _fire() {
    // Never interrupts a reminder already in progress — the person is still
    // working through the last one.
    if (ref.read(activeDhikrReminderProvider) != null) return;
    // On a phone the OS delivers the reminders as notifications (see
    // features/mobile_reminders); popping one up from this in-process timer
    // as well would double every dhikr while the app is open.
    if (!ref.read(appPlatformProvider).remindsInProcess) return;
    // Paused from the tray: the tick passes, the timer keeps its rhythm.
    if (ref.read(reminderPauseProvider) != null) return;
    final settings = ref.read(dhikrSettingsProvider);
    final entry = pickReminder(
      settings.entries,
      _random,
      useChance: settings.useChance,
    );
    if (entry != null) {
      ref.read(activeDhikrReminderProvider.notifier).show(entry);
    }
  }

  /// Which entry a reminder should show. With [useChance] off, every entry —
  /// including one whose chance is 0 — counts as being at [dhikrChanceMax];
  /// the chances stay on the entries themselves, unread, so switching the
  /// option back on picks up where it left off.
  static DhikrEntry? pickReminder(
    List<DhikrEntry> entries,
    Random random, {
    required bool useChance,
  }) {
    if (useChance) return pickWeighted(entries, random);
    if (entries.isEmpty) return null;
    return entries[random.nextInt(entries.length)];
  }

  /// Weighted random pick over `chance`: an entry's odds are its own chance
  /// divided by the sum of every candidate's chance, so raising one entry's
  /// chance only pulls share away from the others, never from some fixed
  /// 0-100 scale. Entries at chance 0 are excluded outright rather than
  /// given a token sliver of probability — 0 means "never", not "rarely".
  @visibleForTesting
  static DhikrEntry? pickWeighted(List<DhikrEntry> entries, Random random) {
    final candidates = entries.where((e) => e.chance > 0).toList();
    if (candidates.isEmpty) return null;
    final totalWeight = candidates.fold<int>(0, (sum, e) => sum + e.chance);
    var roll = random.nextInt(totalWeight);
    for (final entry in candidates) {
      if (roll < entry.chance) return entry;
      roll -= entry.chance;
    }
    return candidates.last;
  }
}

final dhikrReminderSchedulerProvider =
    NotifierProvider<DhikrReminderScheduler, DateTime?>(
  DhikrReminderScheduler.new,
);
