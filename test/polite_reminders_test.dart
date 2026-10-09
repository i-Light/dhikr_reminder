import 'dart:math';

import 'package:dhikr_reminder/core/quiet_hours.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_host.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/windows/native_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_overlay.dart';

const _entries = [
  DhikrEntry(id: 1, name: 'one'),
  DhikrEntry(id: 2, name: 'two'),
  DhikrEntry(id: 3, name: 'three'),
];

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 1, 1, hour, minute);

void main() {
  group('QuietHours', () {
    const night = QuietHours(enabled: true);

    test('a window across midnight holds both sides of it', () {
      expect(night.contains(_at(23, 30)), isTrue);
      expect(night.contains(_at(2)), isTrue);
      expect(night.contains(_at(12)), isFalse);
    });

    test('the start is quiet and the end is not', () {
      expect(night.contains(_at(23)), isTrue);
      expect(night.contains(_at(6)), isFalse);
      expect(night.contains(_at(5, 59)), isTrue);
    });

    test('off is never quiet, and neither is an empty window', () {
      expect(const QuietHours().contains(_at(2)), isFalse);
      expect(
        const QuietHours(enabled: true, startMinutes: 60, endMinutes: 60)
            .contains(_at(1)),
        isFalse,
      );
    });

    test('a window inside one day works', () {
      const lunch =
          QuietHours(enabled: true, startMinutes: 12 * 60, endMinutes: 14 * 60);
      expect(lunch.contains(_at(13)), isTrue);
      expect(lunch.contains(_at(15)), isFalse);
    });
  });

  group('planReminders', () {
    test('leaves reminders that fall in quiet hours out of the plan', () {
      final now = _at(20);
      final plan = planReminders(
        now: now,
        interval: const Duration(hours: 1),
        entries: _entries,
        useChance: false,
        random: Random(1),
        count: 14,
        quiet: const QuietHours(enabled: true),
      );

      expect(plan, isNotEmpty);
      expect(plan.every((r) => !const QuietHours(enabled: true).contains(r.at)),
          isTrue);
      // 21:00 and 22:00 are kept, then nothing until 06:00.
      expect(plan.first.at, _at(21));
      expect(plan[1].at, _at(22));
      expect(plan[2].at, DateTime(2026, 1, 2, 6));
    });

    test('never repeats a dhikr straight away while there is another', () {
      for (var seed = 0; seed < 30; seed++) {
        final plan = planReminders(
          now: _at(9),
          interval: const Duration(minutes: 10),
          entries: _entries,
          useChance: false,
          random: Random(seed),
          count: 40,
        );
        for (var i = 1; i < plan.length; i++) {
          expect(plan[i].entry.id, isNot(plan[i - 1].entry.id));
        }
      }
    });

    test('a single dhikr is allowed to repeat, there is nothing else', () {
      final plan = planReminders(
        now: _at(9),
        interval: const Duration(minutes: 10),
        entries: const [DhikrEntry(id: 1, name: 'only')],
        useChance: false,
        random: Random(1),
        count: 5,
      );
      expect(plan, hasLength(5));
    });

    test('a muted dhikr is never brought back by the no-repeat rule', () {
      final plan = planReminders(
        now: _at(9),
        interval: const Duration(minutes: 10),
        entries: const [
          DhikrEntry(id: 1, name: 'loud', chance: 5),
          DhikrEntry(id: 2, name: 'muted', chance: 0),
        ],
        useChance: true,
        random: Random(2),
        count: 20,
      );
      expect(plan.every((r) => r.entry.id == 1), isTrue);
    });
  });

  group('the Windows moment check', () {
    test('free means the reminder comes', () {
      expect(
        const UserState(notificationState: 5, idleSeconds: 3).shouldHoldReminder,
        isFalse,
      );
    });

    test('a full-screen app, a game, a presentation, quiet time and a locked '
        'PC hold it', () {
      for (final state in [1, 2, 3, 4, 6]) {
        expect(
          UserState(notificationState: state, idleSeconds: 0).shouldHoldReminder,
          isTrue,
          reason: 'state $state',
        );
      }
    });

    test('being away for a quarter of an hour holds it', () {
      expect(
        const UserState(notificationState: 5, idleSeconds: 14 * 60)
            .shouldHoldReminder,
        isFalse,
      );
      expect(
        const UserState(notificationState: 5, idleSeconds: 15 * 60)
            .shouldHoldReminder,
        isTrue,
      );
    });
  });

  group('an ignored card', () {
    testWidgets('closes by itself, so it cannot block the ones after it',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final reminders = container.read(activeDhikrReminderProvider.notifier);

      reminders.show(_entries.first);
      expect(container.read(activeDhikrReminderProvider), isNotNull);
      await tester.pump(
        ActiveDhikrReminderNotifier.idleTimeout - const Duration(seconds: 1),
      );
      expect(container.read(activeDhikrReminderProvider), isNotNull);
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(activeDhikrReminderProvider), isNull);
    });

    testWidgets('keeps waiting while the person is counting', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final reminders = container.read(activeDhikrReminderProvider.notifier);

      reminders.show(const DhikrEntry(id: 9, name: 'x', amount: 50));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(minutes: 2));
        reminders.increment();
      }
      // Ten minutes in, but the last tap was a moment ago.
      expect(container.read(activeDhikrReminderProvider), isNotNull);
      reminders.dismiss();
    });
  });

  group('the syncer', () {
    test('hands quiet hours to the native side', () async {
      final overlay = FakeOverlay(allowed: true);
      const quiet = QuietHours(enabled: true, startMinutes: 1320, endMinutes: 300);

      await MobileReminderSyncer(overlay, random: Random(1)).sync(
        settings: const DhikrSettings(
          entries: _entries,
          intervalMinutes: 30,
          isLoaded: true,
          quiet: quiet,
        ),
        locale: const Locale('en'),
        now: _at(12),
      );

      expect(overlay.quiet, quiet);
      expect(
        overlay.scheduled!.every((r) => !quiet.contains(r.at)),
        isTrue,
      );
    });
  });

  group('the quiet hours row', () {
    testWidgets('is off, then on with its window, and is remembered',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NotificationsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The settings card is folded; open it.
      await tester.tap(find.byKey(const ValueKey('collapsible-header')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('quiet-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('quiet-change')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('quiet-switch')));
      await tester.pumpAndSettle();

      expect(container.read(dhikrSettingsProvider).quiet.enabled, isTrue);
      expect(find.byKey(const ValueKey('quiet-change')), findsOneWidget);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(NotificationsScreen)));
      expect(find.textContaining(l10n.quietChange), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
