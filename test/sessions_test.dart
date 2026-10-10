import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/features/library/application/favourites_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_screen.dart';
import 'package:dhikr_reminder/features/sessions/session_progress.dart';
import 'package:dhikr_reminder/features/sessions/session_runner.dart';
import 'package:dhikr_reminder/features/sessions/sessions_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _a = DhikrEntry(id: 1, name: 'سبحان الله', amount: 2);
const _b = DhikrEntry(id: 2, name: 'الحمد لله', amount: 1);
const _c = DhikrEntry(id: 3, name: 'الله أكبر', amount: 1);

/// Counts the card on screen through, one tap at a time.
void _countThrough(ProviderContainer container) {
  final active = container.read(activeDhikrReminderProvider.notifier);
  final amount = container.read(activeDhikrReminderProvider)!.entry.amount;
  for (var i = 0; i < amount; i++) {
    active.increment();
  }
}

void main() {
  group('what a session goes through', () {
    test('morning and evening are the library groups, countable ones only', () {
      final morning = sessionItems(SessionKind.morning, const []);
      final evening = sessionItems(SessionKind.evening, const []);
      expect(morning, isNotEmpty);
      expect(evening, isNotEmpty);
      expect(
        morning.every(
          (i) => i.isRemindable && i.tags.contains(DhikrTag.morning),
        ),
        isTrue,
      );
      expect(
        evening.every(
          (i) => i.isRemindable && i.tags.contains(DhikrTag.evening),
        ),
        isTrue,
      );
    });

    test('my wird is the starred entries in order, without reading material',
        () {
      final reading = dhikrLibrary.firstWhere((i) => !i.isRemindable);
      final say = dhikrLibrary.where((i) => i.isRemindable).take(2).toList();
      final wird = sessionItems(
        SessionKind.wird,
        [say[1], reading, say[0]],
      );
      expect(wird, [say[1], say[0]]);
    });

    test('a dhikr that is not in the reminders gets an id that cannot clash',
        () {
      final item = sessionItems(SessionKind.morning, const []).first;
      final entry = sessionEntry(item, const [], ownCounts: false);
      expect(entry.id, lessThan(0));
      expect(entry.libraryId, item.id);
      expect(entry.name, item.text);
      expect(entry.amount, item.count.clamp(dhikrAmountMin, dhikrAmountMax));
      // The same dhikr always gets the same id, so its counts add up.
      expect(sessionEntry(item, const [], ownCounts: false).id, entry.id);
    });

    test('one in the reminders keeps its entry; morning uses the sources count',
        () {
      final item = sessionItems(SessionKind.morning, const []).first;
      final saved = [
        DhikrEntry(
          id: 7,
          name: item.text,
          amount: 99,
          dailyGoal: 500,
          libraryId: item.id,
        ),
      ];
      final morning = sessionEntry(item, saved, ownCounts: false);
      expect(morning.id, 7);
      expect(morning.dailyGoal, 500);
      expect(morning.amount, item.count.clamp(dhikrAmountMin, dhikrAmountMax));

      final wird = sessionEntry(item, saved, ownCounts: true);
      expect(wird.id, 7);
      expect(wird.amount, 99);
    }, skip: !Features.wird);
  });

  group('the runner', () {
    ProviderContainer make() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('puts the first dhikr on the card as "1 of 3"', () {
      final container = make();
      container
          .read(sessionRunProvider.notifier)
          .start(SessionKind.wird, [_a, _b, _c]);

      final card = container.read(activeDhikrReminderProvider)!;
      expect(card.entry, _a);
      expect(card.step, 1);
      expect(card.steps, 3);
      expect(card.inSession, isTrue);
      expect(container.read(sessionRunProvider)!.index, 0);
    });

    test('an empty session does nothing', () {
      final container = make();
      container.read(sessionRunProvider.notifier).start(SessionKind.wird, []);
      expect(container.read(sessionRunProvider), isNull);
      expect(container.read(activeDhikrReminderProvider), isNull);
    });

    testWidgets('counting one through brings the next, and the last ends it',
        (tester) async {
      final container = make();
      container
          .read(sessionRunProvider.notifier)
          .start(SessionKind.wird, [_a, _b, _c]);

      _countThrough(container);
      expect(container.read(activeDhikrReminderProvider)!.isComplete, isTrue);
      // Held for a beat so the person sees it finish...
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(activeDhikrReminderProvider)!.entry, _a);
      // ...and swapped for the next just before the card would clear.
      await tester.pump(DhikrTimers.dismissDelay);
      var card = container.read(activeDhikrReminderProvider)!;
      expect(card.entry, _b);
      expect(card.step, 2);
      expect(card.count, 0);

      _countThrough(container);
      await tester.pump(DhikrTimers.dismissDelay);
      card = container.read(activeDhikrReminderProvider)!;
      expect(card.entry, _c);
      expect(card.step, 3);

      // The last: the session is over as soon as it is counted through.
      _countThrough(container);
      expect(container.read(sessionRunProvider), isNull);
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    });

    testWidgets('a card cleared right after it was counted through carries on',
        (tester) async {
      final container = make();
      container
          .read(sessionRunProvider.notifier)
          .start(SessionKind.wird, [_a, _b]);
      _countThrough(container);
      // What the app's card host does once the dwell is over.
      container.read(activeDhikrReminderProvider.notifier).dismiss();
      expect(container.read(activeDhikrReminderProvider)!.entry, _b);
      container.read(sessionRunProvider.notifier).stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
      await tester.pump(DhikrTimers.dismissDelay);
    });

    test('closing the card before it is finished ends the session', () {
      final container = make();
      container
          .read(sessionRunProvider.notifier)
          .start(SessionKind.wird, [_a, _b]);
      container.read(activeDhikrReminderProvider.notifier).increment();
      container.read(activeDhikrReminderProvider.notifier).dismiss();

      expect(container.read(sessionRunProvider), isNull);
      expect(container.read(activeDhikrReminderProvider), isNull);
    });

    test('another card taking over ends the session', () {
      final container = make();
      container
          .read(sessionRunProvider.notifier)
          .start(SessionKind.wird, [_a, _b]);
      container.read(activeDhikrReminderProvider.notifier).show(_c);

      expect(container.read(sessionRunProvider), isNull);
      // The other card is left alone.
      expect(container.read(activeDhikrReminderProvider)!.entry, _c);
    });

    test('back and forward move between the dhikr, and stop at the ends', () {
      final container = make();
      final runner = container.read(sessionRunProvider.notifier);
      runner.start(SessionKind.wird, [_a, _b, _c]);

      // At the first there is nowhere back to go.
      runner.previous();
      expect(container.read(sessionRunProvider)!.index, 0);

      runner.skip();
      final card = container.read(activeDhikrReminderProvider)!;
      expect(card.entry, _b);
      expect(card.step, 2);
      expect(card.count, 0);

      runner.skip();
      expect(container.read(activeDhikrReminderProvider)!.entry, _c);
      // At the last there is nowhere forward to go.
      runner.skip();
      expect(container.read(sessionRunProvider)!.index, 2);
      expect(container.read(activeDhikrReminderProvider)!.entry, _c);

      runner.previous();
      expect(container.read(activeDhikrReminderProvider)!.entry, _b);
      expect(container.read(activeDhikrReminderProvider)!.step, 2);
    });

    test('going back to a dhikr starts it from nothing', () {
      final container = make();
      final runner = container.read(sessionRunProvider.notifier);
      runner.start(SessionKind.wird, [_a, _b]);
      container.read(activeDhikrReminderProvider.notifier).increment();
      expect(container.read(activeDhikrReminderProvider)!.count, 1);

      runner.skip();
      runner.previous();
      final card = container.read(activeDhikrReminderProvider)!;
      expect(card.entry, _a);
      expect(card.count, 0);
      // Still in the session after all that moving about.
      expect(container.read(sessionRunProvider), isNotNull);
    });

    testWidgets('moving on while a dhikr is finishing does not also advance',
        (tester) async {
      final container = make();
      final runner = container.read(sessionRunProvider.notifier);
      runner.start(SessionKind.wird, [_a, _b, _c]);
      runner.skip();
      _countThrough(container);
      // Finished, and the swap to the next is waiting; the person goes back.
      runner.previous();
      await tester.pump(DhikrTimers.dismissDelay);
      expect(container.read(activeDhikrReminderProvider)!.entry, _a);
      expect(container.read(sessionRunProvider)!.index, 0);
      runner.stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    });

    test('a dhikr counted through is remembered for the day', () async {
      SharedPreferences.setMockInitialValues({});
      final container = make();
      const first = DhikrEntry(id: -1, name: 'x', amount: 1, libraryId: 'one');
      const second = DhikrEntry(id: -2, name: 'y', amount: 1, libraryId: 'two');
      container
          .read(sessionRunProvider.notifier)
          .start(SessionKind.morning, [first, second]);
      _countThrough(container);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final today = dhikrDayKey(DateTime.now());
      final progress = container.read(sessionProgressProvider);
      expect(progress.doneIn(SessionKind.morning, today), {'one'});
      expect(progress.doneIn(SessionKind.evening, today), isEmpty);
      // Not for another day.
      expect(progress.doneIn(SessionKind.morning, '2001-01-01'), isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(sessionProgressPrefsKey), contains('"one"'));
      container.read(sessionRunProvider.notifier).stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    });

    test('a card shown outside a session has no "of" on it', () {
      final container = make();
      container.read(activeDhikrReminderProvider.notifier).show(_a);
      expect(container.read(activeDhikrReminderProvider)!.inSession, isFalse);
    });
  }, skip: !Features.sessions);

  group('the screen', () {
    Widget app(ProviderContainer container) => UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SessionsScreen(),
          ),
        );

    testWidgets('morning starts a session over the morning group',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container));

      expect(find.text('Morning azkar'), findsOneWidget);
      expect(find.text('Evening azkar'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('session-morning')));
      await tester.pump();

      final run = container.read(sessionRunProvider)!;
      expect(run.kind, SessionKind.morning);
      expect(
        run.steps.length,
        sessionItems(SessionKind.morning, const []).length,
      );
      final card = container.read(activeDhikrReminderProvider)!;
      expect(card.step, 1);
      expect(card.steps, run.steps.length);
      container.read(sessionRunProvider.notifier).stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    });

    testWidgets('shows how far each session has got, and carries on from there',
        (tester) async {
      final morning = sessionItems(SessionKind.morning, const []);
      final today = dhikrDayKey(DateTime.now());
      SharedPreferences.setMockInitialValues({
        sessionProgressPrefsKey:
            '{"day":"$today","morning":["${morning[0].id}","${morning[1].id}"]}',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(find.text('2 of ${morning.length} done'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-morning-progress')),
        findsOneWidget,
      );
      // Untouched sessions show no bar.
      expect(
        find.byKey(const ValueKey('session-evening-progress')),
        findsNothing,
      );
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('session-morning')));
      await tester.pump();
      // Carries on at the third.
      expect(container.read(activeDhikrReminderProvider)!.step, 3);
      expect(container.read(sessionRunProvider)!.index, 2);
      container.read(sessionRunProvider.notifier).stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    });

    testWidgets('says plainly when a session is finished, and offers it again',
        (tester) async {
      final evening = sessionItems(SessionKind.evening, const []);
      final today = dhikrDayKey(DateTime.now());
      final ids = evening.map((i) => '"${i.id}"').join(',');
      SharedPreferences.setMockInitialValues({
        sessionProgressPrefsKey: '{"day":"$today","evening":[$ids]}',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(find.text('All done today'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Again'), findsOneWidget);

      // Again goes through it from the top.
      await tester.tap(find.byKey(const ValueKey('session-evening')));
      await tester.pump();
      expect(container.read(sessionRunProvider)!.index, 0);
      container.read(sessionRunProvider.notifier).stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    });

    testWidgets("yesterday's progress is not today's", (tester) async {
      final morning = sessionItems(SessionKind.morning, const []);
      SharedPreferences.setMockInitialValues({
        sessionProgressPrefsKey:
            '{"day":"2001-01-01","morning":["${morning[0].id}"]}',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(find.text('Start'), findsNWidgets(3));
      expect(find.textContaining('done'), findsNothing);
    });

    testWidgets('my wird waits for a star, then runs the starred entries',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(app(container));

      final wird = find.byKey(const ValueKey('session-wird'));
      expect(tester.widget<FilledButton>(wird).onPressed, isNull);
      expect(
        find.text('Star any dhikr in the library and it joins your wird here.'),
        findsOneWidget,
      );

      final item = dhikrLibrary.firstWhere((i) => i.isRemindable);
      await tester.runAsync(() async {
        await container.read(favouritesProvider.notifier).toggle(item.id);
      });
      await tester.pump();

      expect(tester.widget<FilledButton>(wird).onPressed, isNotNull);
      await tester.tap(wird);
      await tester.pump();

      final run = container.read(sessionRunProvider)!;
      expect(run.kind, SessionKind.wird);
      expect(run.steps.single.libraryId, item.id);
      container.read(sessionRunProvider.notifier).stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    }, skip: !Features.wird);
  }, skip: !Features.sessions);

  testWidgets('the card says "3 of 31" where it says its title in a session',
      (tester) async {
    tester.view.physicalSize = const Size(1120, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DhikrReminderSurface(
            reminder: const ActiveDhikrReminder(entry: _a, step: 3, steps: 31),
            onTap: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('3 of 31'), findsOneWidget);
  }, skip: !Features.sessions);

  group('the side buttons on a session card', () {
    Widget card({
      required Locale locale,
      VoidCallback? previous,
      VoidCallback? next,
      required VoidCallback onTap,
      bool inSession = true,
    }) =>
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DhikrReminderSurface(
              reminder: ActiveDhikrReminder(
                entry: _a,
                step: inSession ? 2 : null,
                steps: inSession ? 3 : null,
              ),
              onTap: onTap,
              onDismiss: () {},
              onPrevious: previous,
              onNext: next,
            ),
          ),
        );

    Future<void> show(WidgetTester tester, Widget app) async {
      tester.view.physicalSize = const Size(1120, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('go back on the left and forward on the right, in English',
        (tester) async {
      var back = 0;
      var forward = 0;
      var taps = 0;
      await show(
        tester,
        card(
          locale: const Locale('en'),
          previous: () => back++,
          next: () => forward++,
          onTap: () => taps++,
        ),
      );

      final left = tester.getCenter(find.byIcon(Icons.chevron_left_rounded));
      final right = tester.getCenter(find.byIcon(Icons.chevron_right_rounded));
      expect(left.dx, lessThan(right.dx));

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect((back, forward), (1, 2));
      // Pressing a button is not a count.
      expect(taps, 0);

      // Arrow keys do the same.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect((back, forward), (2, 3));
      expect(taps, 0);
    });

    testWidgets('go back on the right in Arabic, where the start is the right',
        (tester) async {
      var back = 0;
      var forward = 0;
      await show(
        tester,
        card(
          locale: const Locale('ar'),
          previous: () => back++,
          next: () => forward++,
          onTap: () {},
        ),
      );

      // The chevrons swap so each points the way it goes: back is on the
      // right, pointing right.
      final right = tester.getCenter(find.byIcon(Icons.chevron_right_rounded));
      final left = tester.getCenter(find.byIcon(Icons.chevron_left_rounded));
      expect(right.dx, greaterThan(left.dx));

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect((back, forward), (1, 0));
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      expect((back, forward), (1, 1));

      // The left key is the left button, which is forward here.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect((back, forward), (1, 2));
    });

    testWidgets('are dim and do nothing where there is nowhere to go',
        (tester) async {
      var forward = 0;
      await show(
        tester,
        card(
          locale: const Locale('en'),
          next: () => forward++,
          onTap: () {},
        ),
      );
      // No back: pressing it does nothing and does not throw.
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(forward, 0);
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      expect(forward, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('are not on a card that is not part of a session',
        (tester) async {
      await show(
        tester,
        card(locale: const Locale('en'), onTap: () {}, inSession: false),
      );
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('are at the bottom of the phone screen, and move on',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(sessionRunProvider.notifier)
          .start(SessionKind.wird, [_a, _b, _c]);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MobileReminderScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 of 3'), findsOneWidget);
      final next = find.byKey(const ValueKey('session-next'));
      final previous = find.byKey(const ValueKey('session-previous'));
      IconButton button(Finder of) => tester.widget<IconButton>(
            find.descendant(of: of, matching: find.byType(IconButton)),
          );
      expect(button(previous).onPressed, isNull);
      // Below the dhikr, near the bottom of the screen.
      expect(tester.getCenter(next).dy, greaterThan(500));

      await tester.tap(next);
      await tester.pump();
      expect(find.text('2 of 3'), findsOneWidget);
      expect(container.read(activeDhikrReminderProvider)!.entry, _b);
      expect(button(previous).onPressed, isNotNull);
      // And it did not count.
      expect(container.read(activeDhikrReminderProvider)!.count, 0);

      await tester.tap(previous);
      await tester.pump();
      expect(find.text('1 of 3'), findsOneWidget);
      container.read(sessionRunProvider.notifier).stop();
      container.read(activeDhikrReminderProvider.notifier).dismiss();
    });
  }, skip: !Features.sessions);
}
