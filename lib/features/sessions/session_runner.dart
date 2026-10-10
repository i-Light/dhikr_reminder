import 'dart:async';

import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/sessions/session_progress.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lists a session can run.
enum SessionKind { morning, evening, wird }

/// The library entries a session of [kind] goes through, in order. The morning
/// and evening lists are the library's own groups; "my wird" is the entries the
/// person starred ([favourites], in the order they were starred). Only entries
/// that can be counted come in: reading material has nothing to tap.
List<DhikrItem> sessionItems(SessionKind kind, List<DhikrItem> favourites) {
  bool countable(DhikrItem item) => item.isRemindable;
  return switch (kind) {
    SessionKind.morning => [
        for (final item in dhikrLibrary)
          if (countable(item) && item.tags.contains(DhikrTag.morning)) item,
      ],
    SessionKind.evening => [
        for (final item in dhikrLibrary)
          if (countable(item) && item.tags.contains(DhikrTag.evening)) item,
      ],
    SessionKind.wird => [
        for (final item in favourites)
          if (countable(item)) item,
      ],
  };
}

/// Where each library entry sits in the library, for the ids of dhikr that are
/// counted in a session without being in the person's reminders.
final Map<String, int> _libraryIndex = {
  for (var i = 0; i < dhikrLibrary.length; i++) dhikrLibrary[i].id: i,
};

/// What the reminder card needs to count [item] in a session.
///
/// A dhikr already in the reminders keeps its own entry (so its daily count and
/// goal are the same ones the reminders use). Any other gets a stand-in with a
/// negative id, which cannot meet a saved one, so its taps still add to today's
/// total without belonging to a reminder. Morning and evening say each dhikr as
/// many times as the sources give; "my wird" says it as many times as the person
/// set for it in their reminders, falling back to the sources.
DhikrEntry sessionEntry(
  DhikrItem item,
  List<DhikrEntry> saved, {
  required bool ownCounts,
}) {
  final fromSources = item.count.clamp(dhikrAmountMin, dhikrAmountMax);
  final own = saved.where((e) => e.libraryId == item.id).firstOrNull;
  if (own != null) {
    return ownCounts ? own : own.copyWith(amount: fromSources);
  }
  return DhikrEntry(
    id: -((_libraryIndex[item.id] ?? 0) + 1),
    name: item.text,
    amount: fromSources,
    libraryId: item.id,
  );
}

/// A session that is under way: its dhikr, and which one is on the card.
@immutable
class SessionRun {
  const SessionRun({required this.kind, required this.steps, this.index = 0});

  final SessionKind kind;
  final List<DhikrEntry> steps;
  final int index;

  DhikrEntry get current => steps[index];
  bool get isLast => index >= steps.length - 1;
  bool get isFirst => index <= 0;

  SessionRun copyWith({int? index}) =>
      SessionRun(kind: kind, steps: steps, index: index ?? this.index);
}

/// Runs a session: puts the first dhikr on the reminder card and, each time one
/// is counted through, the next, with "3 of 31" where the card says its title.
///
/// It uses the one card the app already has, so there is nothing new to learn,
/// and it only ever listens while a session is running. Closing the card
/// before a dhikr is finished ends the session; so does anything else taking
/// the card over.
class SessionRunner extends Notifier<SessionRun?> {
  Timer? _advance;

  @override
  SessionRun? build() {
    ref.onDispose(() => _advance?.cancel());
    ref.listen<ActiveDhikrReminder?>(activeDhikrReminderProvider, _onCard);
    return null;
  }

  /// Begins a session over [steps], at [startIndex] (to carry on where the
  /// person left off); does nothing when there are none.
  void start(SessionKind kind, List<DhikrEntry> steps, {int startIndex = 0}) {
    if (steps.isEmpty) return;
    _advance?.cancel();
    state = SessionRun(
      kind: kind,
      steps: steps,
      index: startIndex.clamp(0, steps.length - 1),
    );
    _showCurrent();
  }

  /// The card's back button: the dhikr before this one. Nothing at the first.
  void previous() => _goTo((state?.index ?? 0) - 1);

  /// The card's forward button: the dhikr after this one, counted through or
  /// not. Nothing at the last.
  void skip() => _goTo((state?.index ?? 0) + 1);

  void _goTo(int index) {
    final run = state;
    if (run == null || index < 0 || index >= run.steps.length) return;
    _advance?.cancel();
    // The new dhikr starts from nothing, so it can be said (again) in full.
    state = run.copyWith(index: index);
    _showCurrent();
  }

  void stop() {
    _advance?.cancel();
    state = null;
  }

  void _showCurrent() {
    final run = state;
    if (run == null) return;
    ref.read(activeDhikrReminderProvider.notifier).show(
          run.current,
          step: run.index + 1,
          steps: run.steps.length,
        );
  }

  void _next() {
    _advance?.cancel();
    final run = state;
    if (run == null) return;
    if (run.isLast) {
      state = null;
      return;
    }
    _goTo(run.index + 1);
  }

  /// This dhikr was counted through: remember it for the day, so the Sessions
  /// screen can say how far along the session is.
  void _markDone(SessionRun run) => unawaited(
        ref
            .read(sessionProgressProvider.notifier)
            .markDone(run.kind, run.current.libraryId),
      );

  void _onCard(ActiveDhikrReminder? previous, ActiveDhikrReminder? next) {
    final run = state;
    if (run == null) return;
    if (next != null) {
      // Some other card took over: the session is not on screen any more.
      if (next.entry.id != run.current.id) {
        stop();
        return;
      }
      if (next.isComplete) _markDone(run);
      if (next.isComplete && !run.isLast) {
        // Swapped for the next dhikr just before the card would have been
        // cleared, so the window stays up from one dhikr to the next instead of
        // closing and opening again. If the card clears first, the branch below
        // carries on all the same.
        _advance?.cancel();
        _advance = Timer(
          DhikrTimers.dismissDelay - const Duration(milliseconds: 150),
          _next,
        );
      } else if (next.isComplete) {
        // The last dhikr: the card clears itself and the session is over.
        state = null;
      }
      return;
    }
    // The card is gone. Counted through (or about to be): carry on. Closed
    // early: the person has finished for now.
    if ((_advance?.isActive ?? false) || (previous?.isComplete ?? false)) {
      _next();
    } else {
      stop();
    }
  }
}

final sessionRunProvider = NotifierProvider<SessionRunner, SessionRun?>(
  SessionRunner.new,
);

/// What the card's back and forward buttons do right now: each is null when
/// there is no session, or nowhere to go (the first and the last dhikr).
({VoidCallback? previous, VoidCallback? next}) sessionNavigation(
    WidgetRef ref) {
  final run = ref.watch(sessionRunProvider);
  if (run == null) return (previous: null, next: null);
  final runner = ref.read(sessionRunProvider.notifier);
  return (
    previous: run.isFirst ? null : runner.previous,
    next: run.isLast ? null : runner.skip,
  );
}
