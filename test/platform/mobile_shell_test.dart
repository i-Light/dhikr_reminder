import 'package:dhikr_reminder/app.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_host.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_screen.dart';
import 'package:dhikr_reminder/features/mobile_reminders/notification_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_overlay.dart';

class _FakeNotifications implements ReminderNotifications {
  bool initialised = false;
  bool askedPermission = false;

  @override
  Future<void> init({required void Function(int entryId) onOpen}) async =>
      initialised = true;

  @override
  Future<bool> requestPermission() async => askedPermission = true;

  @override
  Future<void> replaceAll(
    List<PlannedReminder> plan, {
    required String title,
  }) async {}
}

ProviderContainer _container(
  PlatformKind kind,
  _FakeNotifications fake, [
  FakeOverlay? overlay,
]) {
  final container = ProviderContainer(overrides: [
    appPlatformProvider.overrideWithValue(AppPlatform(kind)),
    reminderNotificationsProvider.overrideWithValue(fake),
    reminderOverlayProvider.overrideWithValue(overlay ?? FakeOverlay()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  testWidgets(
      'on Android the app starts the notification plumbing and shows the '
      'counter over the app while a reminder is active', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fake = _FakeNotifications();
    final container = _container(PlatformKind.android, fake);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DhikrReminderApp(),
      ),
    );
    await tester.pump();

    expect(fake.initialised, isTrue);
    expect(fake.askedPermission, isTrue);
    expect(find.byType(MobileReminderScreen), findsNothing);

    container
        .read(activeDhikrReminderProvider.notifier)
        .show(const DhikrEntry(id: 1, name: 'dhikr text', amount: 3));
    await tester.pump();

    expect(find.byType(MobileReminderScreen), findsOneWidget);
    expect(find.text('dhikr text'), findsOneWidget);

    // Let the debounced schedule sync run out, then unmount: no timer may be
    // left pending when the test ends.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('on Windows no notification plumbing is started', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final fake = _FakeNotifications();
    final container = _container(PlatformKind.windows, fake);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DhikrReminderApp(),
      ),
    );
    await tester.pump();

    expect(fake.initialised, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets(
      'taps made on the overlay while the app was closed are counted '
      'when it starts', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final overlay = FakeOverlay(allowed: true, taps: {4: 12});
    final container = _container(
      PlatformKind.android,
      _FakeNotifications(),
      overlay,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DhikrReminderApp(),
      ),
    );
    await tester.pump();

    expect(container.read(dhikrStatsProvider).todayFor(4), 12);
    expect(overlay.drains, greaterThanOrEqualTo(1));

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
