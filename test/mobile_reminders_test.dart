import 'dart:math';

import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_host.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_screen.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_overlay.dart';

const _entries = [
  DhikrEntry(id: 1, name: 'one'),
  DhikrEntry(id: 2, name: 'two', amount: 3),
];

void main() {
  group('reminderPlanLength', () {
    test('is a day of reminders, kept between 8 and 64', () {
      expect(reminderPlanLength(const Duration(minutes: 30)), 48);
      expect(reminderPlanLength(const Duration(minutes: 1)), 64);
      expect(reminderPlanLength(const Duration(minutes: 120)), 12);
      expect(reminderPlanLength(const Duration(minutes: 600)), 8);
    });
  });

  group('planReminders', () {
    final now = DateTime(2026, 1, 1, 9);

    test('spaces reminders one interval apart with unique ids', () {
      final plan = planReminders(
        now: now,
        interval: const Duration(minutes: 30),
        entries: _entries,
        useChance: false,
        random: Random(1),
        count: 4,
      );

      expect(plan.map((p) => p.at), [
        now.add(const Duration(minutes: 30)),
        now.add(const Duration(minutes: 60)),
        now.add(const Duration(minutes: 90)),
        now.add(const Duration(minutes: 120)),
      ]);
      expect(plan.map((p) => p.id).toSet().length, 4);
    });

    test('never plans an entry muted to chance 0 when chance is on', () {
      final plan = planReminders(
        now: now,
        interval: const Duration(minutes: 10),
        entries: const [
          DhikrEntry(id: 1, name: 'muted', chance: 0),
          DhikrEntry(id: 2, name: 'loud', chance: 5),
        ],
        useChance: true,
        random: Random(3),
      );

      expect(plan, isNotEmpty);
      expect(plan.every((p) => p.entry.id == 2), isTrue);
    });

    test('is empty when nothing can be picked', () {
      expect(
        planReminders(
          now: now,
          interval: const Duration(minutes: 10),
          entries: const [DhikrEntry(id: 1, name: 'muted', chance: 0)],
          useChance: true,
          random: Random(1),
        ),
        isEmpty,
      );
    });

    test('leaves out reminders that fall inside a pause', () {
      final plan = planReminders(
        now: now,
        interval: const Duration(minutes: 30),
        entries: _entries,
        useChance: false,
        random: Random(1),
        pausedUntil: now.add(const Duration(minutes: 70)),
        count: 4,
      );

      expect(plan.map((p) => p.at), [
        now.add(const Duration(minutes: 90)),
        now.add(const Duration(minutes: 120)),
      ]);
    });
  });

  group('MobileReminderSyncer', () {
    const settings = DhikrSettings(
      entries: _entries,
      intervalMinutes: 30,
      isLoaded: true,
    );

    test('waits for the saved settings before scheduling anything', () async {
      final overlay = FakeOverlay(allowed: true);

      await MobileReminderSyncer(overlay).sync(
        settings: const DhikrSettings.loading(),
        locale: const Locale('en'),
      );

      expect(overlay.scheduled, isNull);
    });

    test('hands the native side the plan, with localized card texts', () async {
      final overlay = FakeOverlay(allowed: true);

      await MobileReminderSyncer(
        overlay,
        random: Random(1),
      ).sync(settings: settings, locale: const Locale('en'));

      expect(overlay.scheduled, hasLength(48));
      // The native side keeps the schedule going on its own at this pace once
      // the plan runs out.
      expect(overlay.interval, const Duration(minutes: 30));
      expect(overlay.title, 'Dhikr reminder');
      expect(overlay.closeLabel, 'Close');
      expect(overlay.tip, 'Touch anywhere to count');
      expect(overlay.dayLabel, "Today's dhikr");
      expect(overlay.pausedUntil, isNull);
    });

    test('schedules the same plan without the overlay permission', () async {
      // The native alarm posts a notification where it cannot draw the card,
      // so the plan is handed over whatever the permission says. It must never
      // be cancelled for lack of the permission.
      final overlay = FakeOverlay(allowed: false);

      await MobileReminderSyncer(
        overlay,
        random: Random(1),
      ).sync(settings: settings, locale: const Locale('en'));

      expect(overlay.scheduled, hasLength(48));
      expect(overlay.cancels, 0);
    });

    test('leaves a pause out of the plan and tells the native side', () async {
      final overlay = FakeOverlay(allowed: true);
      final now = DateTime(2026, 1, 1, 9);
      final until = now.add(const Duration(minutes: 70));

      await MobileReminderSyncer(overlay, random: Random(1)).sync(
        settings: settings,
        locale: const Locale('en'),
        pausedUntil: until,
        now: now,
      );

      expect(overlay.pausedUntil, until);
      expect(overlay.scheduled!.every((r) => !r.at.isBefore(until)), isTrue);
      expect(overlay.scheduled!.first.at, now.add(const Duration(minutes: 90)));
    });

    test('a pause that is over is no pause', () async {
      final overlay = FakeOverlay(allowed: true);
      final now = DateTime(2026, 1, 1, 9);

      await MobileReminderSyncer(overlay, random: Random(1)).sync(
        settings: settings,
        locale: const Locale('en'),
        pausedUntil: now.subtract(const Duration(minutes: 5)),
        now: now,
      );

      expect(overlay.pausedUntil, isNull);
      expect(overlay.scheduled, hasLength(48));
    });

    test('hands the native side everything it needs to show a reminder', () {
      final reminder = PlannedReminder(
        id: 3,
        at: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        entry: const DhikrEntry(id: 7, name: 'dhikr text', amount: 33),
      );

      expect(reminder.toOverlayMap(), {
        'id': 3,
        'at': 1700000000000,
        'dhikrId': 7,
        'text': 'dhikr text',
        'amount': 33,
        'goal': 0,
        'translit': '',
      });
    });

    test('and the daily goal, so the card can show how far today has got', () {
      final reminder = PlannedReminder(
        id: 3,
        at: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        entry: const DhikrEntry(
          id: 7,
          name: 'dhikr text',
          amount: 33,
          dailyGoal: 100,
        ),
      );

      expect(reminder.toOverlayMap()['goal'], 100);
    });
  });

  testWidgets('the mobile counter counts taps and shows completion', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(activeDhikrReminderProvider.notifier)
        .show(_entries[1]); // amount 3

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
    expect(find.text('0 / 3'), findsOneWidget);
    // No daily goal set, so no day counter; and no session counter at all.
    expect(find.text("Today's dhikr"), findsNothing);
    expect(find.text('Session'), findsNothing);

    final tap = find.byKey(const ValueKey('mobile-reminder-tap-area'));
    await tester.tap(tap);
    await tester.tap(tap);
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(tap);
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(container.read(activeDhikrReminderProvider)!.isComplete, isTrue);
    // The idle timer of a card nobody closes would still be pending.
    container.read(activeDhikrReminderProvider.notifier).dismiss();
  });

  testWidgets('a dhikr with a daily goal shows its own today / goal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(activeDhikrReminderProvider.notifier).show(
          const DhikrEntry(id: 7, name: 'with goal', amount: 3, dailyGoal: 100),
        );

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
    await tester.tap(find.byKey(const ValueKey('mobile-reminder-tap-area')));
    await tester.pump();

    expect(find.text("Today's dhikr"), findsOneWidget);
    expect(find.text('1 / 100'), findsOneWidget);
    expect(find.text('Session'), findsNothing);
    container.read(activeDhikrReminderProvider.notifier).dismiss();
  });
}
