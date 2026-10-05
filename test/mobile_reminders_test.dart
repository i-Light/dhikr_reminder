import 'dart:math';

import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_host.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_screen.dart';
import 'package:dhikr_reminder/features/mobile_reminders/notification_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifications implements ReminderNotifications {
  List<PlannedReminder>? lastPlan;
  String? lastTitle;

  @override
  Future<void> init({required void Function(int entryId) onOpen}) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> replaceAll(
    List<PlannedReminder> plan, {
    required String title,
  }) async {
    lastPlan = plan;
    lastTitle = title;
  }
}

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
    test('waits for the saved settings before scheduling anything', () async {
      final fake = _FakeNotifications();

      await MobileReminderSyncer(fake).sync(
        settings: const DhikrSettings.loading(),
        locale: const Locale('en'),
      );

      expect(fake.lastPlan, isNull);
    });

    test('replaces the schedule with a localized title', () async {
      final fake = _FakeNotifications();
      const settings = DhikrSettings(
        entries: _entries,
        intervalMinutes: 30,
        isLoaded: true,
      );

      await MobileReminderSyncer(fake, random: Random(1))
          .sync(settings: settings, locale: const Locale('en'));

      expect(fake.lastPlan, hasLength(48));
      expect(fake.lastTitle, 'Dhikr reminder');
    });
  });

  testWidgets('the mobile counter counts taps and shows completion',
      (tester) async {
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
    // No daily goal set: only the session counter is shown, no day counter.
    expect(find.text('Session'), findsOneWidget);
    expect(find.text('Today'), findsNothing);

    final tap = find.byKey(const ValueKey('mobile-reminder-tap-area'));
    await tester.tap(tap);
    await tester.tap(tap);
    await tester.pump();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(tap);
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(container.read(activeDhikrReminderProvider)!.isComplete, isTrue);
  });

  testWidgets('a dhikr with a daily goal shows its own today / goal',
      (tester) async {
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

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('1 / 100'), findsOneWidget);
  });
}
