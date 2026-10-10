import 'dart:async';
import 'dart:convert';

import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/sessions/session_runner.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const sessionProgressPrefsKey = 'dhikr_reminder.sessions.progress';

/// Which dhikr of each session have been counted through today. It starts again
/// empty each day, so a session is "done" for the day and the next morning it is
/// to do again.
@immutable
class SessionProgress {
  const SessionProgress({this.day = '', this.done = const {}});

  /// The day ([dhikrDayKey]) these belong to.
  final String day;

  /// The library ids counted through, by session.
  final Map<SessionKind, Set<String>> done;

  /// The ids done today in [kind], given today's key (none if these are older).
  Set<String> doneIn(SessionKind kind, String today) =>
      day == today ? (done[kind] ?? const {}) : const {};

  @override
  bool operator ==(Object other) =>
      other is SessionProgress &&
      other.day == day &&
      mapEquals(
        {for (final e in other.done.entries) e.key: e.value.length},
        {for (final e in done.entries) e.key: e.value.length},
      );

  @override
  int get hashCode => Object.hash(day, done.length);
}

/// Remembers the progress through the sessions, on this device only. Read from
/// disk when the Sessions screen (or a session) first asks, never at startup.
class SessionProgressNotifier extends Notifier<SessionProgress> {
  Future<void> _ready = Future<void>.value();

  String get _today => dhikrDayKey(ref.read(dhikrStatsClockProvider)());

  @override
  SessionProgress build() {
    _ready = _load();
    return const SessionProgress();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      final raw = prefs.getString(sessionProgressPrefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['day'] != _today) return;
      final done = <SessionKind, Set<String>>{};
      for (final kind in SessionKind.values) {
        final ids = decoded[kind.name];
        if (ids is List) done[kind] = {...ids.whereType<String>()};
      }
      state = SessionProgress(day: _today, done: done);
    } catch (_) {
      // No progress is a fine answer.
    }
  }

  /// [libraryId] of [kind] has been counted through.
  Future<void> markDone(SessionKind kind, String? libraryId) async {
    if (libraryId == null) return;
    await _ready;
    if (!ref.mounted) return;
    final today = _today;
    final done = {
      for (final entry in state.done.entries)
        if (state.day == today) entry.key: entry.value,
    };
    final ids = {...(done[kind] ?? const <String>{}), libraryId};
    if (state.day == today &&
        (state.done[kind]?.contains(libraryId) ?? false)) {
      return;
    }
    done[kind] = ids;
    state = SessionProgress(day: today, done: done);
    if (!StorageGuard.canWrite) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        sessionProgressPrefsKey,
        jsonEncode({
          'day': today,
          for (final entry in done.entries)
            entry.key.name: entry.value.toList(),
        }),
      );
    } catch (_) {
      // Progress that was not remembered costs one tick after a restart.
    }
  }
}

final sessionProgressProvider =
    NotifierProvider<SessionProgressNotifier, SessionProgress>(
  SessionProgressNotifier.new,
);
