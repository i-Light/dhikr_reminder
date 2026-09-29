import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dhikrPrefsKey = 'dhikr_reminder.dhikr.entries';
const _dhikrNextIdPrefsKey = 'dhikr_reminder.dhikr.nextId';
const _dhikrIntervalPrefsKey = 'dhikr_reminder.dhikr.reminderIntervalMinutes';
const _dhikrUseChancePrefsKey = 'dhikr_reminder.dhikr.useChance';
const _dhikrMutedPrefsKey = 'dhikr_reminder.dhikr.muted';

/// Bounds for [DhikrSettings.intervalMinutes] — how many minutes sit between
/// one reminder toast and the next.
const dhikrReminderIntervalDefault = 30;
const dhikrReminderIntervalMin = 1;
const dhikrReminderIntervalMax = 120;

/// Bounds for [DhikrEntry.chance] — a relative weight, not a percentage of
/// anything in particular. Every entry defaults to the same, maximum weight
/// so a freshly added dhikr is exactly as likely to be picked as the rest
/// until someone deliberately turns it down (or to 0, to mute it).
///
/// The scale is 0-10 rather than 0-100 because it was never a percentage and
/// a hundred steps only made it look like one. Ten is plenty to say "this one
/// twice as often as that one", which is the entire question it answers.
const dhikrChanceMin = 0;
const dhikrChanceMax = 10;
const dhikrChanceDefault = 10;

/// The smallest repetition count an entry may carry. One, not zero: a dhikr
/// you are reminded to say zero times is not a reminder, and the "count up
/// freely with no target" mode that zero used to mean was never asked for.
const dhikrAmountMin = 1;
const dhikrAmountMax = 1000;

/// Bumped when the persisted shape changes in a way old data has to be
/// converted through. 1 was the original 0-100 chance scale with amounts
/// allowed to be 0; 2 is the 0-10 scale with a floor of 1 on amount.
const _dhikrSchemaVersion = 2;
const _dhikrSchemaPrefsKey = 'dhikr_reminder.dhikr.schema';

/// One azkar reminder: how many repetitions and how likely it is to be the
/// one picked when a reminder fires. Per-device, same as
/// `PythonEnvironmentSettings`.
class DhikrEntry {
  const DhikrEntry({
    required this.id,
    required this.name,
    this.amount = dhikrAmountMin,
    this.chance = dhikrChanceDefault,
  });

  /// Stable across renames/reordering — rows are keyed on this, not their
  /// position, so an in-progress edit or delete never lands on the wrong row.
  final int id;
  final String name;
  final int amount;

  /// Relative weight in the reminder scheduler's weighted pick — see
  /// `DhikrReminderScheduler.pickWeighted`. Not a percentage: two entries
  /// both at 100 are equally likely regardless of how many other entries
  /// exist. 0 means this dhikr never fires as a reminder.
  final int chance;

  DhikrEntry copyWith({String? name, int? amount, int? chance}) {
    return DhikrEntry(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      chance: chance ?? this.chance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'chance': chance,
      };

  /// [rescaleChance] converts a weight saved on the old 0-100 scale. Applied
  /// only when the stored schema says so — see [_rescaleChance] for why a
  /// blind clamp would have been wrong.
  factory DhikrEntry.fromJson(
    Map<String, dynamic> json, {
    bool rescaleChance = false,
  }) {
    // Falls back to the pre-rename 'frequencyPerHour' key so entries saved
    // before that field became 'chance' don't silently reset to the default
    // weight on the next load.
    final storedChance = (json['chance'] as int?) ??
        (json['frequencyPerHour'] as int?) ??
        dhikrChanceDefault;
    return DhikrEntry(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: (json['amount'] as int? ?? dhikrAmountMin)
          .clamp(dhikrAmountMin, dhikrAmountMax),
      chance: (rescaleChance ? _rescaleChance(storedChance) : storedChance)
          .clamp(dhikrChanceMin, dhikrChanceMax),
    );
  }

  /// 0-100 -> 0-10, preserving what the number meant rather than what it was.
  ///
  /// Rounded *up* for anything above zero. Clamping instead would have turned
  /// every weight from 10 to 100 into a flat 10 — silently making a dhikr
  /// someone had turned down to 20 exactly as frequent as one they had left at
  /// 100. Rounding up rather than to nearest matters at the bottom: 4 must not
  /// become 0, because 0 is the one value with a meaning of its own ("never"),
  /// and nothing should become muted because the scale changed.
  static int _rescaleChance(int old) {
    if (old <= 0) return 0;
    return (old / 10).ceil().clamp(1, dhikrChanceMax);
  }
}

/// Seeded on first run. Azkar text is content, not UI chrome — it stays in
/// Arabic regardless of the app's display language, same way a quoted verse
/// wouldn't be translated just because the surrounding UI is in English.
const _defaultDhikrEntries = [
  DhikrEntry(id: 0, name: 'سبحان الله'),
  DhikrEntry(id: 1, name: 'الحمد لله'),
  DhikrEntry(id: 2, name: 'الله أكبر'),
  DhikrEntry(id: 3, name: 'لا إله إلا الله'),
  DhikrEntry(id: 4, name: 'أستغفر الله'),
];

/// Everything the dhikr feature persists, in one state object: the entries,
/// the reminder interval, and — critically — whether any of it has actually
/// come back from disk yet.
///
/// The [isLoaded] flag exists because a `Notifier` has to return something
/// synchronously from `build()` while `SharedPreferences` is still being
/// awaited, and the only honest something is the seed defaults. Without a
/// way to tell "defaults, because that's genuinely what's saved" apart from
/// "defaults, because we haven't looked yet", two things went wrong on every
/// restart: the scheduler could fire a dhikr the user had muted or deleted
/// (the seeds are all at full chance), and the settings card could latch the
/// seeds into its draft and write them back over the saved list on the next
/// save. Both callers now wait for this flag instead of guessing.
///
/// Entries and interval share one state (and one load) rather than sitting in
/// two providers because they're written by the same Save button, read by the
/// same scheduler, and come from the same prefs read — splitting them only
/// ever meant two races instead of one.
@immutable
class DhikrSettings {
  const DhikrSettings({
    required this.entries,
    required this.intervalMinutes,
    required this.isLoaded,
    this.useChance = false,
    this.isMuted = false,
  });

  /// What the app shows before the first prefs read completes: the seeds,
  /// flagged as provisional so nothing acts on them.
  const DhikrSettings.loading()
      : entries = _defaultDhikrEntries,
        intervalMinutes = dhikrReminderIntervalDefault,
        useChance = false,
        isMuted = false,
        isLoaded = false;

  final List<DhikrEntry> entries;
  final int intervalMinutes;

  /// Whether [DhikrEntry.chance] takes part in picking the next reminder.
  /// Off by default: with it off every entry is treated as being at
  /// [dhikrChanceMax], so they are all equally likely, and the stored chances
  /// are left untouched for whenever it is switched back on.
  final bool useChance;

  /// Silences the sound a reminder makes. Toggled from the tray menu as well
  /// as the settings card, so it applies immediately rather than waiting on
  /// the card's Save button.
  final bool isMuted;

  /// True once the persisted values have been read (or the read has failed
  /// and the defaults stand as the real answer). Nothing should schedule a
  /// reminder or seed an editable draft from this state until it's true.
  final bool isLoaded;

  DhikrSettings copyWith({
    List<DhikrEntry>? entries,
    int? intervalMinutes,
    bool? useChance,
    bool? isMuted,
    bool? isLoaded,
  }) {
    return DhikrSettings(
      entries: entries ?? this.entries,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      useChance: useChance ?? this.useChance,
      isMuted: isMuted ?? this.isMuted,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class DhikrSettingsNotifier extends Notifier<DhikrSettings> {
  int _nextId = _defaultDhikrEntries.length;

  @override
  DhikrSettings build() {
    unawaited(_loadPersisted());
    return const DhikrSettings.loading();
  }

  /// Hands out a fresh id for a row added in the UI before it's saved.
  int allocateId() => _nextId++;

  /// Reads both keys off one `SharedPreferences` instance and publishes the
  /// result in a single state write, so there's no intermediate moment where
  /// the entries are real but the interval isn't. Ends by marking the state
  /// loaded no matter what — a failed read means the defaults *are* the
  /// answer, and callers blocked on [DhikrSettings.isLoaded] have to be let
  /// through rather than left waiting forever.
  Future<void> _loadPersisted() async {
    var entries = _defaultDhikrEntries;
    var intervalMinutes = dhikrReminderIntervalDefault;
    var useChance = false;
    var isMuted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      _nextId = prefs.getInt(_dhikrNextIdPrefsKey) ?? _nextId;

      // Absent means either a fresh install (nothing to convert) or data
      // written before the version existed, which is exactly schema 1.
      final storedSchema = prefs.getInt(_dhikrSchemaPrefsKey) ??
          (prefs.containsKey(_dhikrPrefsKey) ? 1 : _dhikrSchemaVersion);
      final needsRescale = storedSchema < 2;

      final raw = prefs.getString(_dhikrPrefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        entries = decoded
            .map((e) => DhikrEntry.fromJson(
                  e as Map<String, dynamic>,
                  rescaleChance: needsRescale,
                ))
            .toList();
      }
      if (needsRescale) {
        // Written straight back on the new scale so the conversion happens
        // exactly once. Without this every load would re-divide, and a weight
        // of 10 would walk down to 1 over ten launches.
        unawaited(_writeEntries(prefs, entries));
      }

      final storedInterval = prefs.getInt(_dhikrIntervalPrefsKey);
      if (storedInterval != null) {
        intervalMinutes = storedInterval.clamp(
          dhikrReminderIntervalMin,
          dhikrReminderIntervalMax,
        );
      }
      useChance = prefs.getBool(_dhikrUseChancePrefsKey) ?? useChance;
      isMuted = prefs.getBool(_dhikrMutedPrefsKey) ?? isMuted;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load persisted dhikr settings; keeping defaults.',
        name: 'dhikr_reminder.dhikr',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
    state = DhikrSettings(
      entries: entries,
      intervalMinutes: intervalMinutes,
      useChance: useChance,
      isMuted: isMuted,
      isLoaded: true,
    );
  }

  Future<void> updateEntries(List<DhikrEntry> entries) async {
    state = state.copyWith(entries: entries, isLoaded: true);
    for (final entry in entries) {
      if (entry.id >= _nextId) _nextId = entry.id + 1;
    }
    await _persist((prefs) => _writeEntries(prefs, entries));
  }

  Future<void> _writeEntries(
    SharedPreferences prefs,
    List<DhikrEntry> entries,
  ) async {
    await prefs.setString(
      _dhikrPrefsKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
    await prefs.setInt(_dhikrNextIdPrefsKey, _nextId);
    await prefs.setInt(_dhikrSchemaPrefsKey, _dhikrSchemaVersion);
  }

  Future<void> updateInterval(int minutes) async {
    final clamped =
        minutes.clamp(dhikrReminderIntervalMin, dhikrReminderIntervalMax);
    state = state.copyWith(intervalMinutes: clamped, isLoaded: true);
    await _persist((prefs) => prefs.setInt(_dhikrIntervalPrefsKey, clamped));
  }

  Future<void> updateUseChance(bool value) async {
    state = state.copyWith(useChance: value, isLoaded: true);
    await _persist((prefs) => prefs.setBool(_dhikrUseChancePrefsKey, value));
  }

  Future<void> updateMuted(bool value) async {
    state = state.copyWith(isMuted: value, isLoaded: true);
    await _persist((prefs) => prefs.setBool(_dhikrMutedPrefsKey, value));
  }

  Future<void> _persist(
    Future<void> Function(SharedPreferences prefs) write,
  ) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (error, stackTrace) {
      developer.log(
        'Failed to persist dhikr settings.',
        name: 'dhikr_reminder.dhikr',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final dhikrSettingsProvider =
    NotifierProvider<DhikrSettingsNotifier, DhikrSettings>(
  DhikrSettingsNotifier.new,
);
