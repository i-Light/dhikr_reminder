import 'dart:async';
import 'dart:convert';

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _daysPrefsKey = 'dhikr_reminder.history.days';
const _showStreakPrefsKey = 'dhikr_reminder.history.showStreak';

/// How many days of totals are kept. Older ones are dropped as new ones arrive.
const historyKeepDays = 400;

/// "2026-10-05" for the day [back] days before [today]. Counts in calendar
/// days, so a clock change never skips or repeats a date.
String dayKeyBack(DateTime today, int back) =>
    dhikrDayKey(DateTime(today.year, today.month, today.day - back));

/// The total counted on the last [days] days up to and including [today].
int totalOverDays(Map<String, int> totals, DateTime today, int days) {
  var sum = 0;
  for (var back = 0; back < days; back++) {
    sum += totals[dayKeyBack(today, back)] ?? 0;
  }
  return sum;
}

/// How many days in a row, ending today, something was counted. A day not over
/// yet that has no count does not break the run: it simply is not counted, so
/// the number never drops in the middle of the day.
int streakDays(Map<String, int> totals, DateTime today) {
  var back = (totals[dayKeyBack(today, 0)] ?? 0) > 0 ? 0 : 1;
  var days = 0;
  while ((totals[dayKeyBack(today, back)] ?? 0) > 0 && back <= historyKeepDays) {
    days++;
    back++;
  }
  return days;
}

/// [totals] without the days older than [historyKeepDays] before [today].
Map<String, int> pruned(Map<String, int> totals, DateTime today) {
  final oldest = dayKeyBack(today, historyKeepDays - 1);
  return {
    for (final entry in totals.entries)
      if (entry.key.compareTo(oldest) >= 0) entry.key: entry.value,
  };
}

/// Reads saved totals; anything malformed is skipped, never fatal.
Map<String, int> decodeTotals(String? raw) {
  if (raw == null) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return {
      for (final entry in decoded.entries)
        if (entry.key is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(entry.key as String) &&
            entry.value is int &&
            (entry.value as int) > 0)
          entry.key as String: entry.value as int,
    };
  } catch (_) {
    return {};
  }
}

/// What was counted on each of the last [historyKeepDays] days, all together,
/// kept on the device so the History page can show it. A small JSON map, written
/// once per burst of taps, never read until the first count or the page.
class HistoryNotifier extends Notifier<Map<String, int>> {
  /// Counts that arrived while the saved totals were still being read.
  final Map<String, int> _early = {};
  bool _loaded = false;
  bool _saving = false;
  bool _dirty = false;

  @override
  Map<String, int> build() {
    unawaited(_load());
    return const {};
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = decodeTotals(prefs.getString(_daysPrefsKey));
      if (!ref.mounted) return;
      final hadEarly = _early.isNotEmpty;
      var merged = Map<String, int>.of(saved);
      _early.forEach((day, count) => merged[day] = (merged[day] ?? 0) + count);
      _early.clear();
      merged = pruned(merged, DateTime.now());
      _loaded = true;
      state = merged;
      // Written back only if something changed: counts made while loading, or
      // days that fell out of the kept window.
      if (hadEarly || !_sameTotals(merged, saved)) unawaited(_save());
    } catch (_) {
      _loaded = true;
    }
  }

  static bool _sameTotals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Adds [count] taps to [day] (a [dhikrDayKey]).
  void add(String day, int count) {
    if (!Features.history || count <= 0) return;
    if (!_loaded) {
      _early[day] = (_early[day] ?? 0) + count;
      return;
    }
    final next = Map<String, int>.of(state)..[day] = (state[day] ?? 0) + count;
    // Dropping the oldest only matters once the map has grown past the limit.
    state = next.length > historyKeepDays ? pruned(next, _parse(day)) : next;
    unawaited(_save());
  }

  DateTime _parse(String day) => DateTime.tryParse(day) ?? DateTime.now();

  Future<void> _save() async {
    if (_saving) {
      _dirty = true;
      return;
    }
    _saving = true;
    try {
      do {
        _dirty = false;
        if (!StorageGuard.canWrite) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_daysPrefsKey, jsonEncode(state));
      } while (_dirty);
    } catch (_) {
      // A total that was not remembered costs one day's number.
    } finally {
      _saving = false;
    }
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, Map<String, int>>(
  HistoryNotifier.new,
);

/// Whether the History page shows the "days in a row" line. On by default; it
/// can be switched off on the page itself. Nothing is ever said about a day
/// missed, only how many there have been in a row.
class ShowStreakNotifier extends Notifier<bool> {
  @override
  bool build() {
    unawaited(_load());
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_showStreakPrefsKey);
      if (saved != null && ref.mounted) state = saved;
    } catch (_) {
      // Keeps the default.
    }
  }

  Future<void> set(bool value) async {
    state = value;
    if (!StorageGuard.canWrite) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showStreakPrefsKey, value);
    } catch (_) {}
  }
}

final showStreakProvider = NotifierProvider<ShowStreakNotifier, bool>(
  ShowStreakNotifier.new,
);
