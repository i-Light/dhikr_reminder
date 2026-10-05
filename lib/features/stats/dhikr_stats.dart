import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dayPrefsKey = 'dhikr_reminder.stats.day';
const _todayPrefsKey = 'dhikr_reminder.stats.todayByDhikr';

/// What has been counted: [session] taps since the app was started, and
/// today's taps per dhikr since midnight (all sessions of the day added
/// together).
@immutable
class DhikrStats {
  const DhikrStats({this.session = 0, this.byDhikr = const <int, int>{}});

  final int session;

  /// Today's taps, by dhikr id.
  final Map<int, int> byDhikr;

  /// Today's taps on [dhikrId]; the numerator of that dhikr's daily goal.
  int todayFor(int dhikrId) => byDhikr[dhikrId] ?? 0;

  /// Today's taps on every dhikr together.
  int get today => byDhikr.values.fold(0, (sum, count) => sum + count);

  @override
  bool operator ==(Object other) =>
      other is DhikrStats &&
      other.session == session &&
      mapEquals(other.byDhikr, byDhikr);

  @override
  int get hashCode => Object.hash(session, Object.hashAll(byDhikr.entries));
}

/// "2026-10-05": the day key [DhikrStatsNotifier] files the daily totals under.
String dhikrDayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The clock the day totals roll over on. Overridden in tests.
final dhikrStatsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Counts every tap on a reminder, per session and per dhikr per day.
///
/// The session total lives in memory (a new launch is a new session); the
/// daily totals are remembered with the day they belong to, so they survive a
/// restart but start again at zero on a new day.
class DhikrStatsNotifier extends Notifier<DhikrStats> {
  String _day = '';

  @override
  DhikrStats build() {
    _day = dhikrDayKey(ref.read(dhikrStatsClockProvider)());
    unawaited(_load());
    return const DhikrStats();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_dayPrefsKey) != _day) return;
      final decoded = jsonDecode(prefs.getString(_todayPrefsKey) ?? '{}');
      final stored = <int, int>{
        for (final entry in (decoded as Map<String, dynamic>).entries)
          if (int.tryParse(entry.key) != null && entry.value is int)
            int.parse(entry.key): entry.value as int,
      };
      // Taps made while this was loading are already in [state]; keep them.
      final merged = Map<int, int>.of(stored);
      state.byDhikr.forEach((id, count) {
        merged[id] = (merged[id] ?? 0) + count;
      });
      state = DhikrStats(session: state.session, byDhikr: merged);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load the daily counts.',
        name: 'dhikr_reminder.stats',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Adds one counted tap on [dhikrId] to the session and to today.
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
    state = DhikrStats(session: state.session + count, byDhikr: byDhikr);
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dayPrefsKey, _day);
      await prefs.setString(
        _todayPrefsKey,
        jsonEncode({
          for (final entry in state.byDhikr.entries)
            '${entry.key}': entry.value,
        }),
      );
    } catch (_) {
      // A count that was not remembered costs one number after a restart.
    }
  }
}

final dhikrStatsProvider =
    NotifierProvider<DhikrStatsNotifier, DhikrStats>(DhikrStatsNotifier.new);
