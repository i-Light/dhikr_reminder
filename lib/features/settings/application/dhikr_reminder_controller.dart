import 'dart:async';
import 'dart:math';

import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
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
/// `DhikrReminderScheduler` populates it on a timer; `DhikrReminderOverlay`
/// (mounted once at the app root, next to `ToastOverlay`) renders it and
/// drives [increment]/[dismiss] from taps.
class ActiveDhikrReminderNotifier extends Notifier<ActiveDhikrReminder?> {
  @override
  ActiveDhikrReminder? build() => null;

  void show(DhikrEntry entry) => state = ActiveDhikrReminder(entry: entry);

  void increment() {
    final current = state;
    if (current == null || current.isComplete) return;
    state = current.copyWith(count: current.count + 1);
  }

  void dismiss() => state = null;
}

final activeDhikrReminderProvider =
    NotifierProvider<ActiveDhikrReminderNotifier, ActiveDhikrReminder?>(
  ActiveDhikrReminderNotifier.new,
);

/// Fires a dhikr reminder every [DhikrSettings.intervalMinutes] minutes,
/// picking which one with a weighted roll over [DhikrEntry.chance].
///
/// Stays idle until [DhikrSettings.isLoaded] — before the saved settings come
/// back from disk the only entries on hand are the seed defaults, every one of
/// them at full chance, so scheduling against them meant a restart could pop up
/// a dhikr the user had muted (chance 0) or deleted outright.
///
/// A `Notifier<void>` rather than a plain service class so it can `ref.watch`
/// the interval and reschedule its own timer whenever it changes — the same
/// "rebuild tears down and re-sets-up its own side effect" shape
/// `NotificationCenter` uses for its per-toast timers, just at the
/// provider's own `build()` instead of per entry. Kept alive for the app's
/// lifetime by `DhikrReminderOverlay` watching it once at the root, same as
/// `ToastOverlay` keeps `NotificationCenter`'s timers alive by existing.
class DhikrReminderScheduler extends Notifier<void> {
  final _random = Random();

  @override
  void build() {
    // Watched narrowly: the timer should restart when the interval changes,
    // not every time an entry is edited in the settings card — a full rebuild
    // per keystroke would keep pushing the next reminder back indefinitely.
    final isLoaded = ref.watch(dhikrSettingsProvider.select((s) => s.isLoaded));
    if (!isLoaded) return;
    final intervalMinutes =
        ref.watch(dhikrSettingsProvider.select((s) => s.intervalMinutes));
    final timer = Timer.periodic(
      // search for minutes / intervalMinutes
      // schedule is also good keyword
      Duration(minutes: intervalMinutes),
      (_) => _fire(),
    );
    ref.onDispose(timer.cancel);
  }

  void _fire() {
    // Never interrupts a reminder already in progress — the person is still
    // working through the last one.
    if (ref.read(activeDhikrReminderProvider) != null) return;
    final entry =
        pickWeighted(ref.read(dhikrSettingsProvider).entries, _random);
    if (entry != null) {
      ref.read(activeDhikrReminderProvider.notifier).show(entry);
    }
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
    NotifierProvider<DhikrReminderScheduler, void>(
  DhikrReminderScheduler.new,
);
