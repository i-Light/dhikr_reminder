import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/features/library/application/favourites_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/sessions/session_runner.dart';
import 'package:dhikr_reminder/features/sessions/sessions_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
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
}
