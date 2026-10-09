import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/history/history.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dayPrefsKey = 'dhikr_reminder.stats.day';
const _todayPrefsKey = 'dhikr_reminder.stats.todayByDhikr';

/// Kept only so the count an older version saved can be removed: the app no
/// longer counts a session, only each dhikr's day.
const _oldSessionPrefsKey = 'dhikr_reminder.stats.session';

/// What has been counted today: the taps on each dhikr since midnight.
///
/// Every dhikr is counted on its own, by its id, so the day counter on a
/// reminder and the progress on the Notifications page are that dhikr's alone.
@immutable
class DhikrStats {
  const DhikrStats({this.day = '', this.byDhikr = const <int, int>{}});

  /// The day key ([dhikrDayKey]) the counts belong to; empty until the first
  /// count or load. It can be yesterday's in an app that has stayed open past
  /// midnight with no tap since.
  final String day;

  /// Today's taps, by dhikr id.
  final Map<int, int> byDhikr;

  /// Today's taps on [dhikrId]; the numerator of that dhikr's daily goal.
  int todayFor(int dhikrId) => byDhikr[dhikrId] ?? 0;

  /// Today's taps on [dhikrId], given today's day key: zero when the counts are
  /// from an earlier day, as in an app left open past midnight with no tap since.
  int forToday(String todayKey, int dhikrId) =>
      day == todayKey ? todayFor(dhikrId) : 0;

  /// Today's taps on every dhikr together.
  int get today => byDhikr.values.fold(0, (sum, count) => sum + count);

  @override
  bool operator ==(Object other) =>
      other is DhikrStats &&
      other.day == day &&
      mapEquals(other.byDhikr, byDhikr);

  @override
  int get hashCode => Object.hash(day, Object.hashAll(byDhikr.entries));
}

/// "2026-10-05": the day key [DhikrStatsNotifier] files the daily totals under.
String dhikrDayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The clock the day totals roll over on. Overridden in tests.
final dhikrStatsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Counts every tap on a reminder, per dhikr per day.
///
/// The counts are remembered, so a restart or an app update loses nothing. They
/// are filed under the day they belong to and start again at zero on a new day.
class DhikrStatsNotifier extends Notifier<DhikrStats> {
  String _day = '';

  /// Saving waits for this, so a tap made while the saved counts are still
  /// being read cannot overwrite them with a smaller number.
  Future<void> _loaded = Future<void>.value();

  @override
  DhikrStats build() {
    _day = dhikrDayKey(ref.read(dhikrStatsClockProvider)());
    _loaded = _load();
    return const DhikrStats();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = <int, int>{};
      if (prefs.getString(_dayPrefsKey) == _day) {
        final decoded = jsonDecode(prefs.getString(_todayPrefsKey) ?? '{}');
        for (final entry in (decoded as Map<String, dynamic>).entries) {
          if (int.tryParse(entry.key) != null && entry.value is int) {
            stored[int.parse(entry.key)] = entry.value as int;
          }
        }
      }
      // Taps made while this was loading are already in [state]; keep them.
      final merged = Map<int, int>.of(stored);
      state.byDhikr.forEach((id, count) {
        merged[id] = (merged[id] ?? 0) + count;
      });
      state = DhikrStats(day: _day, byDhikr: merged);
      // The session count of earlier versions is of no use any more.
      unawaited(prefs.remove(_oldSessionPrefsKey));
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load the saved counts.',
        name: 'dhikr_reminder.stats',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Adds one counted tap on [dhikrId] to today.
  void recordTap(int dhikrId) => recordTaps(dhikrId, 1);

  /// Adds [count] taps on [dhikrId] at once: the ones made on the Android
  /// overlay while the app was closed.
  void recordTaps(int dhikrId, int count) {
    if (count <= 0) return;
    final today = dhikrDayKey(ref.read(dhikrStatsClockProvider)());
    final rolledOver = today != _day;
    _day = today;
    final byDhikr = rolledOver ? <int, int>{} : Map<int, int>.of(state.byDhikr);
    byDhikr[dhikrId] = (byDhikr[dhikrId] ?? 0) + count;
    state = DhikrStats(day: today, byDhikr: byDhikr);
    // The History page's daily totals (a no-op while that feature is off).
    if (Features.history) ref.read(historyProvider.notifier).add(today, count);
    unawaited(_save());
  }

  bool _saving = false;
  bool _dirty = false;
  String? _savedDay;

  /// Saves the counts. Taps come in bursts (a person counting a hundred), and
  /// on Windows every write rewrites the whole settings file, so a tap that
  /// arrives while a save is running does not start another: it marks the
  /// state dirty and one more save, with everything counted by then, follows.
  Future<void> _save() async {
    if (_saving) {
      _dirty = true;
      return;
    }
    _saving = true;
    try {
      await _loaded;
      do {
        _dirty = false;
        if (!StorageGuard.canWrite) return;
        final prefs = await SharedPreferences.getInstance();
        // The day key changes once a day; writing it every tap was a second
        // whole-file write for nothing.
        if (_savedDay != _day) {
          await prefs.setString(_dayPrefsKey, _day);
          _savedDay = _day;
        }
        await prefs.setString(
          _todayPrefsKey,
          jsonEncode({
            for (final entry in state.byDhikr.entries)
              '${entry.key}': entry.value,
          }),
        );
      } while (_dirty);
    } catch (_) {
      // A count that was not remembered costs one number after a restart.
    } finally {
      _saving = false;
    }
  }
}

final dhikrStatsProvider = NotifierProvider<DhikrStatsNotifier, DhikrStats>(
  DhikrStatsNotifier.new,
);
